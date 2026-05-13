Git commit description, explain the changes you made here

---
__*Leave above in PR description, copy the below into a comment*__
___

### Tracking
- [ ] **[Link to Epic/Issue]**

### Standard development
- [ ] Update / add chart templates, values, and `NOTES.txt` as needed
- [ ] Run `helm lint` and `helm template` locally against the changed chart(s)
- [ ] Verify the chart installs and upgrades cleanly on a test cluster

### Labels checklist
- [ ] Add a docs label (exactly one): `docs-changelog-only`, `docs-needed`, or `docs-not-needed`
- [ ] Add at least one component label: `memgraph`, `memgraph-ha`, `memgraph-lab`, or `infrastructure`
- [ ] Add at least one type label: `bug`, `feature`, or `infrastructure`
- [ ] Assign the PR to a milestone
    - If not known, set for a later milestone

### Documentation checklist
- [ ] Write a release note, including added/changed clauses
    - What has changed? What does it mean for a user? What should a user do with it? [#{{PR_number}}]({{link to the PR}})
- [ ] **[ Documentation PR link memgraph/documentation#XXXX ]**
    - [ ] Is back linked to this development PR
