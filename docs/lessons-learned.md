# Lessons learned

1. **n8n runs each node once per input item.** A Google Sheets *Clear → Read → Append* chain fed with 83 items fired 83 times and hit the API rate limit (429). Fix: `Limit(1)` before the Clear, then read all rows once and append.
2. **Merge needs both inputs.** A parallel branch that returns 0 items cuts the chain. Fix: *Always Output Data* on the query and filters that preserve one item.
3. **Parallel branches multiply downstream work.** Two inputs into one node ran it twice per item; sequencing the reads fixed the duplicate inserts.
4. **`NULL` is never equal to `NULL`.** A unique key that includes `propiedad_id` never deduplicates bank rows that have no property yet; give each source its own key (the bank's transaction ID).
5. **Never hardcode the month.** A hardcoded date in an Insert node wrote a corrected row into the wrong month; compute it dynamically from the schedule.
6. **Business parameters belong in data, not code.** Changing a fee is an `UPDATE`, not a workflow edit and redeploy.
7. **Validate against the client's real history early.** Exact match on real figures found a VAT-formula discrepancy that no unit test would have.
8. **Ask for the rule when the spreadsheet and the agreed criterion disagree.** Where the client's own sheet and the agreed rule differed on a threshold, the documented agreement won and the difference was recorded.
9. **Hand over like a product.** Empty your own credentials before transferring admin, remove your own access last, document restore, and keep secrets out of documents and chats.
