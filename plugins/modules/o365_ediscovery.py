#!/usr/bin/python
# -*- coding: utf-8 -*-


# Copyright 2020 Colton Hughes <colton.hughes@firemon.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


ANSIBLE_METADATA = {'status': ['stableinterface'],
                    'supported_by': 'community',
                    'version': '1.0'}

DOCUMENTATION = '''
---
module: o365_ediscovery
version_added: "2.9.10"
short_description: Creates an ediscovery hold for the user provided
description:
     - The Module adds an eDiscovery hold for the user provided including their mailbox and OneDrive
options:
  hold_enabled:
    description:
      - Whether or not the hold will be enabled
    required: true
    default: null
    aliases: []
  user_email:
    description:
      - Email to be added to the hold
    required: true
    default: null
    aliases: []
  o365_username:
    description:
      - Username with permission to modify eDiscovery Cases
    required: true
    default: null
    aliases: []
  o365_password:
    description:
      - Password matching username with permission to modify eDiscovery Cases
    required: true
    default: null
    aliases: []
author: "Colton Hughes <colton.hughes@firemon.com>"
'''

EXAMPLES = '''
- name: Create a mailbox/oneDrive hold for John Doe
  o365_ediscovery:
    user_email: john.doe@example.com
    o365_username: global_admin@onmicrosoft.com
    o365_password: P@ssw0rd!
    hold_enabled: true
'''
RETURN = '''
casename:
  description: Name of case the hold will be placed in
  returned: changed
  type: string
  sample: "2020 Q3 Terminated Employees"
current_quarter:
  description: Current quarter dynamically determined
  returned: always
  type: integer
  sample: 3
hold_name:
  description: Hold name that is dynamically created
  returned: changed
  type: string
  sample: "user mailbox hold 9/2/2020"
hold_status:
  description: Status of hold
  returned: changed
  type: string
  sample: "Created (or Exists)"
'''