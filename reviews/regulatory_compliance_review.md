# Regulatory & Compliance Expert Review

**Persona**: STR Regulatory and Compliance Expert
**Property**: 159 NE 6th St #4307, Miami, FL 33132 (Natiivo)
**Report Version**: v2 (Generated March 09, 2026)
**Reviewer Focus**: Regulatory data accuracy, zoning compliance, HOA rules, tax obligations, licensing requirements, completeness of compliance information

---

## Overall Assessment

The report demonstrates awareness of regulatory complexity and correctly flags several compliance concerns, but it falls short of the depth and specificity that an investor needs to confidently navigate Miami's STR regulatory landscape. Key areas are vague, conflicting, or missing entirely.

**Compliance Score Given**: 66/100
**My Assessment**: The score is reasonable given the data gaps, but the report should more forcefully communicate that the investor cannot legally operate until multiple unresolved items are confirmed.

---

## Findings

### 1. Zoning Status Left Unresolved -- CRITICAL

**Severity: Critical**

The report states:
> "Zoning Status Unclear" -- "Verify with Miami planning"

and in the AI narrative:
> "Miami zoning and city rules are not fully confirmed and create some legal uncertainty"

**What's wrong**: The report identifies zoning as unclear but does not specify the actual zoning district for this parcel (likely T6-36a-O or similar under Miami 21 transect code). For a $610K investment, telling the buyer "verify with Miami planning" is insufficient. The report should either:
- State the actual zoning code and whether STRs are a permitted use, conditional use, or prohibited
- Explicitly flag that the system was unable to determine the zoning and rate this as a blocking unknown

**What I'd expect**: The zoning district code, a statement on whether STRs under 30 days are permitted by-right under that code, and a reference to the relevant Miami 21 transect zone provisions.

---

### 2. City of Miami STR Registration Requirement Missing -- CRITICAL

**Severity: Critical**

The report mentions needing "Miami-Dade County and City of Miami vacation rental licenses/registrations" in the compliance narrative (line 815), but provides no specifics about:
- The City of Miami's STR registration program (Ordinance 13937, effective 2019, updated multiple times)
- The requirement to register with the City's short-term rental registry
- The annual registration/renewal fees
- The 2% City of Miami resort tax that applies in addition to county/state taxes
- Potential penalties for operating without registration

**What's shown** (line 815):
> "obtain the required Miami-Dade County and City of Miami vacation rental licenses/registrations"

**What I'd expect**: Specific mention of the City of Miami STR registration program, its annual fee, the ordinance number, and a direct link or reference to the application process. This is not optional -- it is a legal prerequisite.

---

### 3. Tax Rate Understated and Lacks Specificity -- MAJOR

**Severity: Major**

The report states:
> "Tax Rate ~12% -- Combined state + local lodging tax" (line 976-977)

The operating expenses show "STR/Tourist Tax" at $1,138/month (line 2527-2534), which on ~$9,482/month revenue equals ~12%.

**What's wrong**: The actual combined tax burden for STR in Miami includes:
- Florida Sales Tax: 6%
- Miami-Dade County Tourist Development Tax (TDT): 6%
- City of Miami Resort Tax: 2% (if applicable in this zone)
- Total: ~13-14%

The "~12%" figure likely underestimates the true obligation. More importantly, the report does not break down which taxes apply, who is responsible for collection (operator vs. platform), or whether platform remittance (e.g., Airbnb collecting Florida sales tax automatically) reduces the operator's filing burden.

**What I'd expect**: A line-by-line tax breakdown showing each tax authority, rate, and whether it's platform-remitted or operator-remitted. The difference between gross booking revenue and net revenue after tax withholding should be explicit.

---

### 4. HOA 3-Night Minimum Conflict Understated -- MAJOR

**Severity: Major**

The executive summary correctly flags:
> "Compliance conflict: Building allows STR but HOA 3-night minimum. Verify HOA rules before proceeding." (line 348)

And the compliance section warns:
> "Building vs HOA: 3-night minimum -- Verify HOA rules before proceeding" (lines 908-910)

**What's wrong**: The report treats this as a "verify" item, but then in the Prerequisites section (line 534-535), it marks "STR Allowed" as passed with "Legal + HOA confirmed". This is contradictory -- you cannot simultaneously say "verify HOA rules before proceeding" and "Legal + HOA confirmed." This creates confusion about whether the investor has a green light or not.

Additionally, the report does not discuss:
- Whether the 3-night minimum is in the HOA Declaration (hard to change) or in HOA Rules (easier to amend)
- Whether the HOA has any other STR-specific rules (noise, guest registration, key handoff procedures, max occupancy per unit)
- Whether the HOA charges an STR fee or requires additional insurance
- Penalty provisions for HOA rule violations

**What I'd expect**: A clear, non-contradictory status. If the HOA rules are not verified, the prerequisite should NOT show as confirmed. The report should also enumerate known HOA STR restrictions beyond just minimum stay.

---

### 5. FL DBPR License Information Too Vague -- MAJOR

**Severity: Major**

The report states:
> "License Available -- FL DBPR license" (lines 964-965)

The evidence artifact shows:
> "Licenses found: 6; Statuses: {'active': 6}" (line 1019) with only 30% confidence

**What's wrong**:
- The report does not specify which DBPR license type is required (likely a Vacation Rental - Condo license under F.S. 509.242)
- It shows 6 active licenses for the building but does not clarify if those are building-level licenses or unit-level licenses -- an important distinction for a condo unit buyer
- The 30% confidence on this evidence is very low, yet the checklist shows a green checkmark, giving false assurance
- The report does not mention the requirement for a Business Tax Receipt (BTR) from the City of Miami, which is separate from the DBPR license

**What I'd expect**: The specific DBPR license category, whether the investor needs their own unit-level license vs. being covered under a building-wide license, the application process timeline, and the cost. Also mention the BTR requirement.

---

### 6. Conflicting Signals Not Adequately Explained -- MAJOR

**Severity: Major**

The report shows two separate amber warnings:
> "Compliance Conflicts Detected" (line 906)
> "Conflicting Signals Detected -- Our sources disagree on STR compliance for this property" (line 923)

The evidence artifact for web_research (line 1031) states:
> "web_research allows STR (conf: 65%); web_research restricts STR (conf: 65%)"

**What's wrong**: A single source simultaneously saying STR is allowed AND restricted at equal confidence is a significant data quality problem that should be explained, not just flagged with a generic "verify independently." The report doesn't explain what the conflicting web research found -- was it about the city ordinance? A pending regulation change? A different building? Without this context, the investor cannot assess the actual risk.

**What I'd expect**: A summary of what the conflicting sources actually say, not just that they conflict. If the system cannot resolve the conflict, it should state what the conflict is about and recommend specific verification steps.

---

### 7. No Mention of Insurance Requirements Specific to STR -- MINOR

**Severity: Minor**

The operating expenses include "HO6 Property Policy" ($148/mo) and "Liability ($1M)" ($67/mo), which is good. However, the regulatory section does not mention:
- Whether the HOA requires specific STR insurance riders
- Whether the DBPR license requires proof of liability insurance
- Whether the standard HO6 policy covers STR activity (many don't without an endorsement)

**What I'd expect**: A note in the regulatory section that STR operations may void standard homeowner insurance policies and that STR-specific coverage (or an endorsement) is required.

---

### 8. No Mention of Fire/Safety/Inspection Requirements -- MINOR

**Severity: Minor**

The compliance section (line 815) vaguely references "safety/inspection requirements" but provides no specifics. In Miami, DBPR-licensed vacation rentals are subject to periodic inspection by the Division of Hotels & Restaurants.

**What I'd expect**: Mention of the DBPR inspection requirement, fire safety equipment mandates (smoke detectors, fire extinguishers, posted evacuation plans), and any City of Miami building code requirements for STR units.

---

### 9. Risk Tab Contradicts Compliance Tab -- MINOR

**Severity: Minor**

The Risk/Confidence tab (lines 3030-3035) states:
> "No Significant Investment Risks Detected"
> "No major financial, regulatory, or market red flags were identified"

This directly contradicts the regulatory tab's "VERIFY REQUIRED" status, two compliance conflicts, and "Medium" confidence. It also contradicts the executive summary's "CAUTION" verdict.

**What I'd expect**: The risk tab should reflect the unresolved regulatory items as at least "manageable" risks, not show zero risks.

---

### 10. No Platform-Specific Compliance Guidance -- SUGGESTION

**Severity: Suggestion**

The report does not mention platform-specific compliance requirements:
- Airbnb requires hosts in Miami to acknowledge local regulations and provide their license number
- Booking.com and VRBO have similar requirements
- The City of Miami may require platforms to verify registration before listing

**What I'd expect**: A brief note on platform compliance requirements, especially since the evidence shows listings on airbnb, vrbo, booking, tripadvisor, and furnished_finder.

---

### 11. No Mention of Pending or Proposed Regulatory Changes -- SUGGESTION

**Severity: Suggestion**

Miami's STR regulatory landscape has been evolving. The report provides a snapshot but does not mention any pending legislation, proposed ordinance amendments, or regulatory trends that could affect future operations.

**What I'd expect**: A brief regulatory outlook section noting whether any changes are pending or anticipated.

---

## Summary Table

| # | Finding | Severity | Status in Report |
|---|---------|----------|-----------------|
| 1 | Zoning district not identified | Critical | Flagged as unclear, no resolution |
| 2 | City of Miami STR registration missing | Critical | Mentioned generically, no specifics |
| 3 | Tax rate understated, no breakdown | Major | Shows ~12%, likely 13-14% |
| 4 | HOA status contradictory (confirmed vs. verify) | Major | Conflicting signals across sections |
| 5 | DBPR license details too vague | Major | Green check at 30% confidence |
| 6 | Conflicting signals unexplained | Major | Flagged but not explained |
| 7 | STR insurance requirements missing | Minor | Not addressed in regulatory section |
| 8 | Fire/safety/inspection requirements missing | Minor | Vague reference only |
| 9 | Risk tab contradicts compliance tab | Minor | Shows "no risks" despite conflicts |
| 10 | Platform compliance guidance absent | Suggestion | Not mentioned |
| 11 | Regulatory outlook missing | Suggestion | Not mentioned |

**Critical: 2 | Major: 4 | Minor: 3 | Suggestion: 2**

---

## Bottom Line

An investor relying solely on this report's regulatory section would have an incomplete understanding of their compliance obligations. The two critical gaps -- unresolved zoning and missing City of Miami registration details -- must be addressed before this report can serve as a reliable compliance guide. The contradictions between sections (HOA "confirmed" vs. "verify," zero risks vs. two compliance conflicts) undermine trust in the report's regulatory analysis.
