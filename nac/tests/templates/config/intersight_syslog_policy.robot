*** Settings ***
Documentation   Verify Syslog Policies
Suite Setup     Login Intersight
Default Tags    intersight    day1    config    syslog_policies
Resource        ../intersight_common.resource

*** Test Cases ***
{% for org in compute.intersight.organizations | default([]) %}
{% for policy in org.policies.syslog | default([]) %}
{% if policy.managed | default(true) %}

Verify Syslog Policy {{ org.name }}/{{ policy.name }}
    ${org_moid}=    Get Org Moid    {{ org.name }}
    ${r}=    GET On Session    intersight_api
    ...    /api/v1/syslog/Policies
    ...    params=$filter=Name eq '{{ policy.name }}' and Organization/Moid eq '${org_moid}'
    ${r}=    Set Variable    ${r.json()}
    Should Be Equal JMESPath Json    ${r}    length(Results)    1
    Should Be Equal JMESPath Json    ${r}    Results[0].Name    {{ policy.name }}
{% if policy.description is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].Description    {{ policy.description }}
{% endif %}
{% if policy.local_min_severity is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].LocalClients[0].MinSeverity    {{ policy.local_min_severity }}
{% endif %}
{% for client in policy.remote_clients | default([]) %}
    Should Be Equal JMESPath Json    ${r}    Results[0].RemoteClients[{{ loop.index0 }}].Hostname    {{ client.hostname }}
{% if client.enabled is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].RemoteClients[{{ loop.index0 }}].Enabled    {{ client.enabled }}
{% endif %}
{% if client.port is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].RemoteClients[{{ loop.index0 }}].Port    {{ client.port }}
{% endif %}
{% if client.protocol is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].RemoteClients[{{ loop.index0 }}].Protocol    {{ client.protocol }}
{% endif %}
{% if client.min_severity is defined %}
    Should Be Equal JMESPath Json    ${r}    Results[0].RemoteClients[{{ loop.index0 }}].MinSeverity    {{ client.min_severity }}
{% endif %}
{% endfor %}

{% else %}

Verify Syslog Policy {{ org.name }}/{{ policy.name }} Not Configured
    ${org_moid}=    Get Org Moid    {{ org.name }}
    ${r}=    GET On Session    intersight_api
    ...    /api/v1/syslog/Policies
    ...    params=$filter=Name eq '{{ policy.name }}' and Organization/Moid eq '${org_moid}'
    ${r}=    Set Variable    ${r.json()}
    Should Be Equal JMESPath Json    ${r}    length(Results)    0

{% if policy.tags | default([]) %}
    ${kv_tags}=    Evaluate    {t['Key']: t['Value'] for t in $r['Results'][0].get('Tags', []) if not t.get('SysTag', False) and t.get('Type', 'KeyValue') == 'KeyValue'}
    ${path_tags}=    Evaluate    {t['Key'] for t in $r['Results'][0].get('Tags', []) if not t.get('SysTag', False) and t.get('Type') == 'PathTag'}
{% for tag in policy.tags %}
{% if tag.type | default('KeyValue') == 'PathTag' %}
    ${all_tag_keys}=    Evaluate    set($kv_tags.keys()) | $path_tags
    Should Contain    ${all_tag_keys}    {{ tag.key }}
{% else %}
    Should Be Equal As Strings    ${kv_tags.get('{{ tag.key }}')}    {{ tag.value }}
{% endif %}
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
{% endfor %}
