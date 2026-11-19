class Rule:
    id = "306"
    description = "Verify the built-in 'default' organization is never treated as managed"
    severity = "HIGH"

    @classmethod
    def match(cls, data):
        results = []
        orgs = data.get("compute", {}).get("intersight", {}).get("organizations", [])
        for org in orgs:
            if org.get("name") == "default" and org.get("managed", True) is not False:
                results.append(
                    "compute.intersight.organizations['default'].managed"
                    " - the built-in 'default' organization cannot be created, renamed, or"
                    " deleted; it must set 'managed: false'"
                )
        return results
