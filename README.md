# Module Documentation
This module is quite simple.
It creates an eDiscovery hold and will dynamically create/place it in the correct case based on quarters.

## Example
```
- name: Create a mailbox/oneDrive hold for John Doe
  o365_ediscovery:
    user_email: john.doe@example.com
    o365_username: global_admin@onmicrosoft.com
    o365_password: P@ssw0rd!
    hold_enabled: true
```
This is a very simple module that I put very little effort in perfecting.  If issues arise feel free to open them or fork and modify at your own discretion.