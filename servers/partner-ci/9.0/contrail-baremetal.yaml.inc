- runner-condition
- inject:
    properties-content: $BAREMETAL_PARAMETERS
- multijob:
    name: >
      'Baremetal DPDK for {fuel-release}.{plugin-name}.{plugin-version}'
    condition: COMPLETED
    projects:
      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_ha_dpdk.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_add_compute.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_delete_compute.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_add_dpdk.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_delete_dpdk.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_add_controller.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_delete_controller.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_add_to_dpdk_sriov.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

- multijob:
    name: >
      'Baremetal SRIOV for {fuel-release}.{plugin-name}.{plugin-version}'
    condition: COMPLETED
    projects:

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_ha_sriov.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_add_compute.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_delete_compute.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_add_sriov.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_delete_sriov.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_add_controller.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_delete_controller.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_dpdk_update_core_repos.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER

      - name: '{fuel-release}.{plugin-name}.{plugin-version}.contrail_sriov_update_core_repos.juniper'
        property-file: build_number
        node-label-name: 'label'
        node-label: 'contrail-baremetal'
        predefined-parameters: |
           CONTRAIL_DISTRIBUTION=juniper
           node=contrail-baremetal
        current-parameters: true
        kill-phase-on: NEVER