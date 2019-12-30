"""
Security Group ingress rule checker

Input event:
    Ingress rule changes in a security group

Detection:
    Detects rules that allow open access from any IP

Response:
    Delete the offending rules
"""

import json
import boto3
from botocore.exceptions import ClientError


# Whitelists - modify as needed
WHITELIST_TCP_PORTS = [80, 443]
WHITELIST_UDP_PORTS = []
WHITELIST_ICMP = True


def detect_violations(data):
    """ Find rule violations """
    rules = data['requestParameters']['ipPermissions'].get('items')
    violations = []
    for rule in rules:
        # First, skip if rule is in whitelisted items
        if (
                rule['ipProtocol'] == 'tcp' and
                rule['fromPort'] == rule['toPort'] and
                rule['fromPort'] in WHITELIST_TCP_PORTS
        ):
            continue
        if (
                rule['ipProtocol'] == 'udp' and
                rule['fromPort'] == rule['toPort'] and
                rule['fromPort'] in WHITELIST_UDP_PORTS
        ):
            continue
        if (
                rule['ipProtocol'] == 'icmp' and
                WHITELIST_ICMP
        ):
            continue
        # Now find violations in the rule
        cidr_ips_v4 = [i['cidrIp'] for i in rule['ipRanges'].get('items', [])]
        cidr_ips_v6 = [i['cidrIpv6'] for i in rule['ipv6Ranges'].get('items', [])]
        if (
                '0.0.0.0/0' in cidr_ips_v4 or
                '::/0' in cidr_ips_v6
        ):
            violations.append(rule)

    return violations


def delete_ingress_rules(sgid, rules):
    """ Delete ingress rules from security group """

    def capped(list_):
        """ Convert list of dicts with capitalized keys """
        result = []
        for dict_ in list_:
            result.append({(lambda w: w[0].upper()+w[1:])(k): v for (k, v) in
                           dict_.items()})
        return result

    def remap(rule):
        """ Convert rule from event data into format accepted by the
        boto3 function """
        return {
            'IpProtocol'      : rule['ipProtocol'],
            'FromPort'        : rule['fromPort'],
            'ToPort'          : rule['toPort'],
            'IpRanges'        : capped(rule['ipRanges'].get('items', [])),
            'Ipv6Ranges'      : capped(rule['ipv6Ranges'].get('items', [])),
        }

    client = boto3.client('ec2')
    # Not storing the response because any errors will be expressed as
    # ClientError
    client.revoke_security_group_ingress(
        GroupId=sgid,
        IpPermissions=[remap(rule) for rule in rules]
    )


def lambda_handler(event, context):
    """ Main function """
    detail = json.loads(event['Records'][0]['Sns']['Message'])['detail']

    # We only care about AuthorizeSecurityGroupIngress events. Do
    # nothing otherwise
    event_name = 'AuthorizeSecurityGroupIngress'
    if detail['eventName'] != event_name:
        print('Not of event {} - skipping'.format(event_name))
        return

    # Collect some useful params
    sgid = detail['requestParameters']['groupId']

    ## DETECTION ##

    violations = detect_violations(detail)
    if not violations:
        print('No violations detected in {} event on {}'.format(event_name, sgid))
        return

    ## ACTION ##

    # Log the violations
    print('Detected ingress rule violations! Pertinent event data follows.')
    fields = ['eventTime', 'userIdentity', 'awsRegion', 'sourceIPAddress',
              'userAgent']
    print(json.dumps({k: v for k, v in detail.items() if k in fields}))
    for rule in violations:
        print('[{}] Ingress rule violation: {}'.format(sgid, json.dumps(rule)))

    # Delete the offending rules
    try:
        delete_ingress_rules(sgid=sgid, rules=violations)
        print('[{}] ACTIONED: Violations successfully deleted!'.format(sgid))
    except ClientError as e:
        print('[{}] Unable to delete violations due to error: {}'.format(sgid, e))
