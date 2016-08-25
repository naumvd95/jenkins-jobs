- runner-condition
- multijob:
    name: 'System tests for {plugin-name} {fuel-release}.{plugin-version}'
    condition: SUCCESSFUL
    projects:
     - name: '{fuel-release}.{plugin-name}.manila_smoke'
       current-parameters: true
       kill-phase-on: NEVER
       property-file: build_number
     - name: '{fuel-release}.{plugin-name}.manila_bvt'
       current-parameters: true
       kill-phase-on: NEVER
       property-file: build_number