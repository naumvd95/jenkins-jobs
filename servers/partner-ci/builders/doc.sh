#!/bin/bash -e
export TESTRAIL_USER=$TREP_TESTRAIL_USER
export TESTRAIL_API_KEY=$TREP_TESTRAIL_PASSWORD
PATH_TO_DOCS="${WORKSPACE}/doc/testing/"
rm -rf ${WORKSPACE}/utility-repo && mkdir ${WORKSPACE}/utility-repo
cd ${WORKSPACE}/utility-repo
git clone https://github.com/ehles/rst2tr.git
[ "${MODERN_MODEL}" == "true" ] && MODEL="${WORKSPACE}/utility-repo/rst2tr/formats/modern_model.yaml" || MODEL="${WORKSPACE}/utility-repo/rst2tr/formats/classic_model.yaml"
if [[ "${CHECK_ONLY}" == "true" ]]; then
  python ${WORKSPACE}/utility-repo/rst2tr/rst2tr/rst2tr.py -n -f $MODEL -v -s  ${PATH_TO_DOCS}
else
  python ${WORKSPACE}/utility-repo/rst2tr/rst2tr/rst2tr.py -f $MODEL -v -s ${PATH_TO_DOCS}
fi
