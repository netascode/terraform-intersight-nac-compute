*** Settings ***
Library   pabot.PabotLib
Library   RequestsLibrary
Library   JSONLibrary
Library   Collections
Library   OperatingSystem
Library   String
Library   packaging.version

*** Variables ***
# Transitional states are polled; any other non-success state fails immediately.
@{PROFILE_TRANSIENT_STATES}    Assigned    Validating    Configuring    Activating
@{WORKFLOW_TRANSIENT_STATES}   NotStarted    InProgress    Waiting
@{HCL_TRANSIENT_STATES}        Not-Evaluated
${NOT_FOUND_GRACE}             2 min

*** Keywords ***
Login Intersight
   ${secret}=   Get Environment Variable   INTERSIGHT_SECRET_KEY
   ${api_key}=   Get Environment Variable   INTERSIGHT_API_KEY
   Evaluate   __import__('sys').path.insert(0, '${CURDIR}') if '${CURDIR}' not in __import__('sys').path else None
   ${auth}=   Evaluate
   ...    intersight_signing.make_intersight_auth($api_key, $secret)
   ...    modules=intersight_signing
   ${headers}=   Create Dictionary   accept=application/json
   ${default_url}=   Get Environment Variable   INTERSIGHT_ENDPOINT_URL   https://intersight.com
   ${url}=   Get Environment Variable   INTERSIGHT_URL   ${default_url}
   Create Custom Session   intersight_api   ${url}   ${auth}   headers=${headers}   verify=True

Should Be Equal Value Json String
   [Arguments]   ${json}    ${json_path}   ${value}=${EMPTY}  ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   ${r_value}=   Set Variable If    (${r_value} == [] or "${r_value[0]}" in ["${EMPTY}", "None"])    not_defined    ${r_value[0]}
   Run Keyword If   "${value}" != "${EMPTY}"   Should Be Equal As Strings    ${r_value}    ${value}    msg=${msg}

Should Be Equal Value Json List
   [Arguments]   ${json}   ${json_path}   ${value}=${None}   ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   Run Keyword If   "${value}" != "${None}"   Lists Should Be Equal   ${r_value}   ${value}   ignore_order=True   msg=${msg}

Should Be Equal JMESPath Json
   [Arguments]   ${json}   ${expression}   ${expected}   ${msg}=${EMPTY}
   ${result}=   Evaluate   jmespath.search('${expression}', $json)   modules=jmespath
   ${result_str}=   Convert To String   ${result}
   Should Be Equal As Strings   ${result_str}   ${expected}   msg=${msg}

Get Cached Moid
   [Documentation]   Return the MOID cached in the suite for key, or ${None}. MOIDs are stable for the lifetime of a run.
   [Arguments]   ${key}
   ${cache}=   Get Variable Value   ${MOID_CACHE}   ${None}
   IF   $cache is None
       ${cache}=   Create Dictionary
       Set Suite Variable   ${MOID_CACHE}   ${cache}
   END
   ${moid}=   Evaluate   $cache.get($key)
   RETURN   ${moid}

Set Cached Moid
   [Arguments]   ${key}   ${moid}
   ${cache}=   Get Variable Value   ${MOID_CACHE}
   Set To Dictionary   ${cache}   ${key}=${moid}

Get Org Moid
   [Documentation]   Look up an Intersight organization MOID by name (cached per suite)
   [Arguments]   ${org_name}
   ${cached}=   Get Cached Moid   org/${org_name}
   IF   $cached is not None
       RETURN   ${cached}
   END
   ${r}=   GET On Session   intersight_api
   ...    /api/v1/organization/Organizations
   ...    params=$filter=Name eq '${org_name}'
   Should Be Equal As Integers   ${r.status_code}   200
   ${data}=   Set Variable   ${r.json()}
   Should Be Equal JMESPath Json   ${data}   length(Results)   1   msg=Organization '${org_name}' not found
   ${moid}=   Evaluate   $data['Results'][0]['Moid']
   Set Cached Moid   org/${org_name}   ${moid}
   RETURN   ${moid}

Get Object Moid
   [Documentation]   Look up any org-scoped Intersight object MOID by endpoint, name, and org MOID (cached per suite)
   [Arguments]   ${endpoint}   ${name}   ${org_moid}
   ${cached}=   Get Cached Moid   ${endpoint}/${org_moid}/${name}
   IF   $cached is not None
       RETURN   ${cached}
   END
   ${r}=   GET On Session   intersight_api
   ...    /api/v1/${endpoint}
   ...    params=$filter=Name eq '${name}' and Organization/Moid eq '${org_moid}'
   Should Be Equal As Integers   ${r.status_code}   200
   ${data}=   Set Variable   ${r.json()}
   Should Be Equal JMESPath Json   ${data}   length(Results)   1   msg=Object '${name}' not found at ${endpoint}
   ${moid}=   Evaluate   $data['Results'][0]['Moid']
   Set Cached Moid   ${endpoint}/${org_moid}/${name}   ${moid}
   RETURN   ${moid}

Get All Results
    [Documentation]   GET all pages ($top/$skip) of an endpoint and return the combined Results list
    [Arguments]   ${endpoint}   ${filter}=${EMPTY}   ${page_size}=100
    ${all}=   Create List
    ${skip}=   Set Variable   0
    WHILE   True
        ${params}=   Set Variable   $top=${page_size}&$skip=${skip}
        ${params}=   Set Variable If   "${filter}" != "${EMPTY}"   ${params}&$filter=${filter}   ${params}
        ${r}=   GET On Session   intersight_api   /api/v1/${endpoint}   params=${params}
        Should Be Equal As Integers   ${r.status_code}   200
        ${results}=   Evaluate   $r.json().get('Results', [])
        Append To List   ${all}   @{results}
        ${count}=   Get Length   ${results}
        IF   ${count} < ${page_size}   BREAK
        ${skip}=   Evaluate   ${skip} + ${page_size}
    END
    RETURN   ${all}

Get Policy Vlans
    [Documentation]   Return {VlanId: VLAN} for all VLANs of an Ethernet network policy, fetched once per suite
    [Arguments]   ${policy_moid}
    ${cache}=   Get Variable Value   ${VLAN_CACHE}   ${None}
    IF   $cache is None
        ${cache}=   Create Dictionary
        Set Suite Variable   ${VLAN_CACHE}   ${cache}
    END
    IF   $policy_moid not in $cache
        ${vlans}=   Get All Results   fabric/Vlans   EthNetworkPolicy/Moid eq '${policy_moid}'
        ${by_id}=   Evaluate   {v['VlanId']: v for v in $vlans}
        Set To Dictionary   ${cache}   ${policy_moid}=${by_id}
    END
    RETURN   ${cache}[${policy_moid}]

Get Vlan Result
    [Documentation]   Return a {Results: [...]} document for one VLAN ID, shaped like a fabric/Vlans query response
    [Arguments]   ${policy_moid}   ${vlan_id}
    ${vlans}=   Get Policy Vlans   ${policy_moid}
    ${results}=   Evaluate   [$vlans[int($vlan_id)]] if int($vlan_id) in $vlans else []
    ${r}=   Create Dictionary   Results=${results}
    RETURN   ${r}

Get Wait Settings
    [Documentation]   Return the polling deadline (monotonic seconds) and interval (seconds). Timeout/interval default
    ...               to 15 min / 30 s, overridable via INTERSIGHT_WAIT_TIMEOUT / INTERSIGHT_WAIT_INTERVAL.
    ${timeout}=   Get Environment Variable   INTERSIGHT_WAIT_TIMEOUT   15 min
    ${interval}=   Get Environment Variable   INTERSIGHT_WAIT_INTERVAL   30 s
    ${deadline}=   Evaluate   time.monotonic() + robot.utils.timestr_to_secs($timeout)   modules=time,robot.utils
    ${interval}=   Evaluate   robot.utils.timestr_to_secs($interval)   modules=robot.utils
    RETURN   ${deadline}   ${interval}

Seconds Until
    [Arguments]   ${deadline}
    ${left}=   Evaluate   $deadline - time.monotonic()   modules=time
    RETURN   ${left}

Profile Should Be Associated
    [Documentation]   Profile (server/Profiles, chassis/Profiles, fabric/SwitchProfiles) reaches ConfigState Associated.
    ...               Polls while the state is transitional, fails immediately on any other state (Failed, Pending-changes, ...).
    [Arguments]   ${endpoint}   ${name}   ${org_moid}
    ${deadline}   ${interval}=   Get Wait Settings
    WHILE   True
        ${r}=   GET On Session   intersight_api
        ...    /api/v1/${endpoint}
        ...    params=$filter=Name eq '${name}' and Organization/Moid eq '${org_moid}'
        ${r}=   Set Variable   ${r.json()}
        Should Be Equal JMESPath Json   ${r}   length(Results)   1   msg=Profile ${name} not found at ${endpoint}
        ${state}=   Evaluate   $r['Results'][0]['ConfigContext']['ConfigState']
        IF   '${state}' == 'Associated'
            RETURN
        END
        IF   $state not in $PROFILE_TRANSIENT_STATES
            Fail   Profile ${name} ConfigState is ${state}
        END
        ${left}=   Seconds Until   ${deadline}
        IF   ${left} <= 0
            Fail   Timed out waiting for profile ${name} to be Associated, ConfigState is ${state}
        END
        Sleep   ${interval}
    END

Get Profile Hardware Moid
    [Documentation]   Return the MOID of the hardware associated with a profile (field: AssociatedServer,
    ...               AssociatedChassis or AssociatedSwitch). Polls only while the profile ConfigState is
    ...               transitional; fails immediately otherwise.
    [Arguments]   ${endpoint}   ${name}   ${org_moid}   ${field}
    ${deadline}   ${interval}=   Get Wait Settings
    WHILE   True
        ${r}=   GET On Session   intersight_api
        ...    /api/v1/${endpoint}
        ...    params=$filter=Name eq '${name}' and Organization/Moid eq '${org_moid}'
        ${r}=   Set Variable   ${r.json()}
        Should Be Equal JMESPath Json   ${r}   length(Results)   1   msg=Profile ${name} not found at ${endpoint}
        ${moid}=   Evaluate   ($r['Results'][0].get('${field}') or {}).get('Moid')
        IF   $moid is not None
            RETURN   ${moid}
        END
        ${state}=   Evaluate   $r['Results'][0]['ConfigContext']['ConfigState']
        IF   $state not in $PROFILE_TRANSIENT_STATES
            Fail   Profile ${name} has no ${field} (ConfigState is ${state})
        END
        ${left}=   Seconds Until   ${deadline}
        IF   ${left} <= 0
            Fail   Timed out waiting for ${field} of profile ${name}, ConfigState is ${state}
        END
        Sleep   ${interval}
    END

Latest Profile Workflow Should Be Completed
    [Documentation]   The most recent workflow associated with the profile reaches WorkflowStatus Completed.
    ...               Polls while NotStarted/InProgress/Waiting, fails immediately on Failed/Terminated/Canceled/Paused.
    ...               A missing workflow only gets a short grace period (NOT_FOUND_GRACE).
    [Arguments]   ${endpoint}   ${name}   ${org_moid}
    ${profile_moid}=   Get Object Moid   ${endpoint}   ${name}   ${org_moid}
    ${deadline}   ${interval}=   Get Wait Settings
    ${grace}=   Evaluate   time.monotonic() + robot.utils.timestr_to_secs($NOT_FOUND_GRACE)   modules=time,robot.utils
    WHILE   True
        ${r}=   GET On Session   intersight_api
        ...    /api/v1/workflow/WorkflowInfos
        ...    params=$filter=AssociatedObject/Moid eq '${profile_moid}'&$orderby=StartTime desc&$top=1
        ${results}=   Evaluate   $r.json()['Results']
        ${count}=   Get Length   ${results}
        IF   ${count} == 0
            ${left}=   Seconds Until   ${grace}
            IF   ${left} <= 0
                Fail   No workflow found for profile ${name}
            END
        ELSE
            ${status}=   Set Variable   ${results[0]['WorkflowStatus']}
            IF   '${status}' == 'Completed'
                RETURN
            END
            IF   $status not in $WORKFLOW_TRANSIENT_STATES
                Fail   Latest workflow of ${name} (${results[0]['Name']}) is ${status}
            END
            ${left}=   Seconds Until   ${deadline}
            IF   ${left} <= 0
                Fail   Timed out waiting for workflow of ${name} (${results[0]['Name']}), status is ${status}
            END
        END
        Sleep   ${interval}
    END

HCL Status Should Be Validated
    [Documentation]   cond/HclStatuses for the hardware reaches Validated. Hardware (model, processor, firmware) must be
    ...               Validated; polls only while Not-Evaluated and fails immediately on other values. The software
    ...               half (OS/driver) is skipped when Intersight has no OS data (Missing-Os-Info /
    ...               Missing-Os-Driver-Info), which nac-compute does not manage; other software states fail.
    [Arguments]   ${moid}   ${label}
    ${deadline}   ${interval}=   Get Wait Settings
    WHILE   True
        ${r}=   GET On Session   intersight_api
        ...    /api/v1/cond/HclStatuses
        ...    params=$filter=ManagedObject/Moid eq '${moid}'
        ${results}=   Evaluate   $r.json()['Results']
        ${count}=   Get Length   ${results}
        Should Be Equal As Integers   ${count}   1   msg=Expected one HCL status for ${label}, found ${count}
        ${hcl}=   Set Variable   ${results[0]}
        ${hw}=   Set Variable   ${hcl['HardwareStatus']}
        ${sw}=   Set Variable   ${hcl['SoftwareStatus']}
        ${reasons}=   Set Variable   ${hcl.get('Reason')}, ${hcl.get('ServerReason')}
        IF   $hw != 'Validated' and $hw not in $HCL_TRANSIENT_STATES
            Fail   Hardware HCL status of ${label} is ${hw} (${reasons})
        END
        IF   $hw == 'Validated' and $sw == 'Validated'
            RETURN
        END
        IF   $hw == 'Validated' and $sw not in $HCL_TRANSIENT_STATES
            IF   'Missing-Os' in $reasons
                Skip   Hardware HCL status of ${label} is Validated, software status is ${sw} (${reasons}): no OS/driver data reported
            END
            Fail   Software HCL status of ${label} is ${sw} (${reasons})
        END
        ${left}=   Seconds Until   ${deadline}
        IF   ${left} <= 0
            Fail   Timed out waiting for HCL status of ${label}, hardware ${hw}, software ${sw}
        END
        Sleep   ${interval}
    END

Critical Alarms Should Be Absent
    [Documentation]   No unacknowledged Critical alarm on the hardware or any of its components
    [Arguments]   ${moid}   ${label}
    ${r}=   GET On Session   intersight_api
    ...    /api/v1/cond/Alarms
    ...    params=$filter=(AffectedMoId eq '${moid}' or AncestorMoId eq '${moid}') and Severity eq 'Critical' and Acknowledge eq 'None'
    ${alarms}=   Evaluate   [(a['Code'], a['Description']) for a in $r.json()['Results']]
    Should Be Empty   ${alarms}   msg=${label} has critical alarms: ${alarms}
