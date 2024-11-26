---
name: Bug Report
about: Create a report to help improve LiveVue
title: 'BUG: '
labels: 'bug'
assignees: ''
---

### Description
<!--
A clear and concise description of what the bug is.
Please try to include reproduction steps, otherwise it might require more time to investigate.
-->

### Actual Behavior
<!-- What actually happened? -->

### Expected Behavior
<!-- What did you expect to happen? -->

## Environment
<!-- Run this command in your project root and paste the output:

```bash
echo "
LiveVue: $(mix hex.info live_vue | grep 'Locked version:' | cut -d ' ' -f3)
Phoenix: $(mix hex.info phoenix | grep 'Locked version:' | cut -d ' ' -f3)
Phoenix LiveView: $(mix hex.info phoenix_live_view | grep 'Locked version:' | cut -d ' ' -f3)
Elixir: $(elixir -v | grep 'Elixir' | cut -d ' ' -f2)
Node: $(node -v)
Npm: $(npm -v)
Vue: $(cd assets && npm list vue | grep -A1 'live_vue@' | grep ' vue@' | cut -d '@' -f2 | head)"
```
-->

```
# Paste the output here
Operating system:
Browser (if relevant):
```
