"""
Security Group ingress rule checker

Input event:
    Ingress rule changes in a security group

Detection:
    Detects rules that allow open access from any IP

Response:
    Reactively delete the offending rules
"""

import json


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
                rule['fromPort'] in WHITELIST_TCP_PORTS and
                rule['toPort'] in WHITELIST_TCP_PORTS
        ):
            continue
        if (
                rule['ipProtocol'] == 'udp' and
                rule['fromPort'] in WHITELIST_UDP_PORTS and
                rule['toPort'] in WHITELIST_UDP_PORTS
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


def trigger_action(**kwargs):
    """ Perform action on violations """
    sgid = kwargs['sgid']
    for rule in kwargs['violations']:
        print('[{}] Ingress rule violation: {}'.format(sgid, json.dumps(rule)))


def lambda_handler(event, context):
    """ Main function """
    detail = json.loads(event['Records'][0]['Sns']['Message'])['detail']

    # We only care about AuthorizeSecurityGroupIngress events. Do
    # nothing otherwise
    event_name = 'AuthorizeSecurityGroupIngress'
    if detail['eventName'] != event_name:
        print('Not a {} event - skipping'.format(event_name))
        return

    # Collect some useful params
    sgid = detail['requestParameters']['groupId']

    # Detection proper
    violations = detect_violations(detail)
    if not violations:
        print('No violations detected in {} event on {}'.format(event_name, sgid))
        return

    # Action proper
    data = {
        'sgid': sgid,
        'violations': violations,
    }
    trigger_action(**data)
