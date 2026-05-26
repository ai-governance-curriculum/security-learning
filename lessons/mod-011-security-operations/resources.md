# Module 11 — Resources

> Primary sources for security operations. Verify URLs at access
> time.

## Detection frameworks

- **MITRE ATT&CK**
  [attack.mitre.org](https://attack.mitre.org/)

- **MITRE ATLAS** (Module 01 also)
  [atlas.mitre.org](https://atlas.mitre.org/)

- **MITRE D3FEND** (defensive techniques mapped to ATT&CK)
  [d3fend.mitre.org](https://d3fend.mitre.org/)

- **Sigma**
  [github.com/SigmaHQ/sigma](https://github.com/SigmaHQ/sigma)
  Generic detection-rule format + community rule library.

- **Sigma specification**
  [github.com/SigmaHQ/sigma-specification](https://github.com/SigmaHQ/sigma-specification)

## Sigma tooling

- **sigma-cli** (official converter)
  [github.com/SigmaHQ/sigma-cli](https://github.com/SigmaHQ/sigma-cli)

- **Uncoder.io** (web-based Sigma converter)
  [uncoder.io](https://uncoder.io/)

## SIEMs (vendor docs for context, not endorsement)

- **Elastic Security**
  [elastic.co/docs](https://www.elastic.co/docs)

- **Microsoft Sentinel**
  [learn.microsoft.com/en-us/azure/sentinel](https://learn.microsoft.com/en-us/azure/sentinel/)

- **Splunk Enterprise Security**
  [docs.splunk.com](https://docs.splunk.com/Documentation)

- **Google Chronicle (now SecOps)**
  [chronicle.security](https://chronicle.security/)

- **Datadog Cloud SIEM**
  [docs.datadoghq.com/security/cloud_siem/](https://docs.datadoghq.com/security/cloud_siem/)

- **Wazuh** (open source)
  [documentation.wazuh.com](https://documentation.wazuh.com/)

## NIST standards

- **NIST SP 800-61 Rev. 2 — Computer Security Incident Handling Guide**
  [csrc.nist.gov/pubs/sp/800/61/r2/final](https://csrc.nist.gov/pubs/sp/800/61/r2/final)
  The canonical IR framework.

- **NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response**
  [csrc.nist.gov/pubs/sp/800/86/final](https://csrc.nist.gov/pubs/sp/800/86/final)

## Threat intel sources

- **CISA Known Exploited Vulnerabilities Catalog**
  [cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)

- **CISA Advisories**
  [cisa.gov/news-events/cybersecurity-advisories](https://www.cisa.gov/news-events/cybersecurity-advisories)

- **OSV** (vulnerability database)
  [osv.dev](https://osv.dev/)

- **NVD** (National Vulnerability Database)
  [nvd.nist.gov](https://nvd.nist.gov/)

## Postmortem references

- **Google SRE: Postmortem culture**
  [sre.google/sre-book/postmortem-culture/](https://sre.google/sre-book/postmortem-culture/)

- **Etsy: Blameless PostMortems**
  [www.etsy.com/codeascraft/blameless-postmortems](https://www.etsy.com/codeascraft/blameless-postmortems)

- **PagerDuty incident response docs**
  [response.pagerduty.com](https://response.pagerduty.com/)

## On-call resources

- **PagerDuty on-call best practices**
  [pagerduty.com/resources/learn/](https://www.pagerduty.com/resources/learn/)

- **Google SRE: Being on-call**
  [sre.google/sre-book/being-on-call/](https://sre.google/sre-book/being-on-call/)

## ML-specific detection references

- **Microsoft AML Threat Matrix**
  [github.com/Azure/counterfit/wiki](https://github.com/Azure/counterfit/wiki) — early MS framework that influenced ATLAS.

- **Google SAIF detection patterns**
  [safety.google/cybersecurity-advancements/saif/](https://safety.google/cybersecurity-advancements/saif/)

## Books

- **The Practice of Network Security Monitoring** by Richard
  Bejtlich (No Starch Press). Foundational NSM text.

- **Intelligence-Driven Incident Response** by Scott Roberts &
  Rebekah Brown (O'Reilly). The intersection of threat intel
  and IR.

- **The Site Reliability Workbook**, especially the chapters
  on managing incidents.

## Cross-references in this curriculum

- [`ai-infra-security-solutions/projects/project-5-security-operations/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-5-security-operations) — Reference SOC project with Sigma rules + playbooks + tabletops.

- [`ai-infra-engineer-solutions/modules/mod-108-monitoring-observability/exercise-09-incident-response-gameday`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-108-monitoring-observability/exercise-09-incident-response-gameday) — Game day reference.

- [`ai-infra-engineer-solutions/modules/mod-108-monitoring-observability/exercise-07-alertmanager-routing`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-108-monitoring-observability/exercise-07-alertmanager-routing) — Alert-routing reference.

## Things deliberately not on this list

- Commercial SIEM "magic quadrant" reports — read with skepticism.
- Vendor IR products without engagement details.
- IR certifications without the experience — useful credentials,
  not substitute for practice.
