# Pihole running on Azure

###  A Proof of Concept 
#### I like Pihole, it kills plenty of adware and makes my browsing experience faster and leaner
#### Instead of having a raspberry PI on my local network or a docker container running PIHOLE I decided to test the service on Azure running on an Ubuntu VM, Standard B2ts v2 (2 vcpus, 1 GiB memory)

***Some considerations and number verifications I'll make:***
1. Query response, Average Response Time 
2. Queries Per second
3. Pihole Uptime
4. Cache Hit Rate
5. Block Rate
6. CPU & Memory Usage
7. Network Load
8. Upstream Resolver Latency
***
***Also, plan to export Pihole logs to Log Analytics**