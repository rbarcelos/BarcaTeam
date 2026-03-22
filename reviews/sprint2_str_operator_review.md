# Sprint 2: STR Operator & Property Manager Review

**Persona**: Experienced Short-Term Rental Operator / Property Manager
**Date**: 2026-03-19
**Sprint**: Model Accuracy Sprint 2
**Reports Reviewed**:
1. 159 NE 6th St #4307, Miami (Natiivo) -- 1BD condo, $610K, CAUTION verdict
2. 5049 Shoreway Loop #10301, Orlando (Vista Cay) -- 3BD condo, $625K, NO-GO verdict
3. 1200 Brickell Bay Dr #2202, Miami (Club at Brickell Bay) -- 3BD condo, $1.1M, NO-GO verdict

**Prior Review**: `reviews/str_operator_review.md` (Sprint 1, 10 findings, 3 Critical)

---

## Confidence Score: 6.5 / 10

Sprint 2 is a meaningful improvement from what I reviewed in Sprint 1. The model now applies the 18% management fee, models variable cost scaling across scenarios, applies ADR-OCC elasticity, and correctly identifies two of three properties as NO-GO. However, several operationally significant issues remain, including a critical HOA fee omission across all three reports.

---

## What Improved Since Sprint 1

### 1. Management Fee Corrected to 18% -- CONFIRMED
All three reports now use 18% management fee. For Natiivo, management is $1,621/mo on $9,006/mo revenue -- that is exactly 18.0%. This is an improvement from the 20% default in Sprint 1 and closer to what I see in the market for full-service STR management in purpose-built buildings.

**Operator Assessment**: 18% is reasonable as a default. For purpose-built STR buildings like Natiivo and Vista Cay, actual rates range 15-20% depending on the management company. 18% sits in the right zone.

### 2. Variable Cost Scaling Across Scenarios -- CONFIRMED
Expenses now correctly differ per scenario. For Natiivo:
- Base OpEx: $50,871/yr
- Optimistic OpEx: $55,735/yr (+9.6%, proportional to +15% revenue increase)
- Conservative OpEx: $44,580/yr (-12.4%, proportional to -19% revenue decrease)

This is a real improvement. In Sprint 1, all scenarios used the same expense number. Variable costs like management fees, STR taxes, and OTA commissions absolutely should scale with revenue.

### 3. ADR-OCC Elasticity -- CONFIRMED
The elasticity coupling is working correctly:
- Natiivo optimistic: ADR $413 (+10.0%) / OCC 82.5% (base 78.9% dampened by -3pp, then rounded = ~82.5%)
- Natiivo conservative: ADR $338 (-10.0%) / OCC 70.7% (base 78.9% boosted by +3pp occupancy, but also -10% ADR reduction path, net ~70.7%)

Wait -- the conservative scenario shows LOWER occupancy AND lower ADR. Let me verify: base OCC 78.9%, conservative OCC 70.7%. That is -8.2pp, not +3pp. The elasticity is supposed to be: lower ADR leads to higher occupancy. But conservative shows both lower ADR (-10%) AND lower occupancy (-8.2pp). This does not follow the documented ADR-OCC coupling (conservative: ADR-10% but OCC+3%).

**This is a remaining issue -- see Finding 2 below.**

### 4. NO-GO Verdicts Correctly Assigned
Orlando and Brickell both correctly receive NO-GO verdicts:
- Orlando: DSCR 0.36x, -$24K/yr cash flow, negative in ALL scenarios including optimistic
- Brickell: DSCR 0.03x, -$64K/yr cash flow, requires 100% occupancy to break even

These are appropriate verdicts. As an operator, I would never touch either of these deals at asking price.

### 5. Risk Warnings Present
Both NO-GO properties now include risk warnings:
- "CRITICAL: Negative cashflow in base scenario"
- "HIGH: Cannot service debt in conservative scenario"
- "MODERATE: Requires 79%/100% occupancy to break even"

This is a major improvement from Sprint 1 where the model showed "No Significant Risks" alongside 0/100 confidence scores.

---

## Remaining Issues

### Finding 1: HOA Fees Missing From All Three Reports -- $0 Across the Board

**Severity: BLOCKER**

All three reports show `hoa_fees: 0.0` in the expense breakdown:

| Property | Building | HOA in Report | Expected HOA (Operator Est.) |
|----------|----------|---------------|------------------------------|
| Natiivo 1BD | Purpose-built STR tower | $0/mo | $800-$1,200/mo |
| Vista Cay 3BD | Resort-style community | $0/mo | $400-$700/mo |
| Brickell Bay 3BD | Luxury condo tower | $0/mo | $600-$1,000/mo |

This was flagged as a Critical finding in my Sprint 1 review (the prior report showed $1,100/mo HOA for Natiivo). Sprint 2 appears to have regressed -- HOA is now **zero** instead of the $1,100 shown previously. For a Natiivo unit, the HOA alone could be $800-$1,200/month given the building amenities (rooftop pool, concierge, fitness center, dog park). For the Brickell Bay property with 24-hour concierge, valet parking, pool, and hot tub, the HOA is likely $800-$1,200/mo.

**Impact on Natiivo**: Adding a realistic $1,000/mo HOA to the base case would shift annual cash flow from +$20,674 to +$8,674. Adding the still-missing cleaning costs ($800-$1,200/mo), the deal goes negative. The CAUTION verdict should likely be NO-GO.

**Impact on Orlando/Brickell**: Both are already NO-GO, so the verdict is correct but the magnitude of losses is understated by $5,000-$14,000/year.

This is a blocker because it directly misstates the profitability of the only property that currently shows positive cash flow.

---

### Finding 2: ADR-OCC Elasticity May Be Inverted in Conservative Scenario

**Severity: Important**

According to the CAP_REVIEW, the elasticity fix should produce:
- Optimistic: ADR +10%, OCC -3pp (higher rates dampen bookings)
- Conservative: ADR -10%, OCC +3pp (lower rates attract more bookings)

Checking Natiivo actuals:
- Base: ADR $375.24, OCC 78.9%
- Optimistic: ADR $412.91 (+10.0%), OCC 82.5% (+3.6pp -- should be -3pp)
- Conservative: ADR $337.60 (-10.0%), OCC 70.7% (-8.2pp -- should be +3pp)

Both directions appear inverted. Optimistic shows HIGHER OCC with higher ADR. Conservative shows LOWER OCC with lower ADR. This is the opposite of what economic elasticity would predict and the opposite of what the sprint documentation says was implemented.

Checking Orlando:
- Base: ADR $247.95, OCC 52.3%
- Optimistic: ADR $272.42 (+9.9%), OCC 54.8% (+2.5pp -- should be -3pp)
- Conservative: ADR $222.99 (-10.1%), OCC 47.1% (-5.2pp -- should be +3pp)

Same pattern -- both directions inverted. The optimistic scenario is now a pure "everything is better" scenario and the conservative is "everything is worse." This defeats the purpose of the elasticity fix, which was supposed to model the economic tradeoff between pricing and volume.

**Operator Reality**: When I raise rates 10%, I do not get more bookings. When I drop rates 10%, I absolutely get more bookings. The model is moving both variables in the same direction, which makes the optimistic scenario too optimistic and the conservative scenario too pessimistic.

---

### Finding 3: STR Tax Rate Shows 12%, Not 14% as Claimed

**Severity: Important**

The CAP_REVIEW states: "Miami now shows 14% (was 12%)" -- but all three reports (including both Miami properties) show:
- `total_lodging_tax: 0.12` (12%)
- `str_tax_rate: 0.12`
- Broken down as: state_sales_tax 6% + tourist_development_tax 6%

The actual Miami-Dade combined STR tax rate is approximately 13-14% when including all applicable taxes (6% state sales + 6% tourist development + 1-2% local discretionary). The data in these reports still shows 12%.

For the Natiivo base case, the difference between 12% and 14% STR tax on $108K revenue is approximately $2,160/year ($180/month). Not deal-breaking alone, but it undermines the claim that AC-3 ("Miami properties show >= 13% combined STR tax") is truly PASS.

---

### Finding 4: Cleaning / Turnover Costs Still Absent

**Severity: Important**

This was Finding 2 (Critical) in my Sprint 1 review and it remains unfixed. None of the three reports include cleaning or turnover costs in the expense breakdown.

For each property at modeled occupancy and a 3-4 night average stay:

| Property | Turnovers/Mo | Cost/Clean | Monthly Cost |
|----------|-------------|------------|-------------|
| Natiivo 1BD (79% occ) | 7-8 | $100-$130 | $700-$1,040 |
| Vista Cay 3BD (52% occ) | 4-5 | $150-$200 | $600-$1,000 |
| Brickell 3BD (45% occ) | 3-4 | $150-$200 | $450-$800 |

Yes, some operators pass cleaning fees to guests. But even with guest-paid cleaning fees:
1. The cleaning fee is subject to the 12%+ STR tax and platform commission (typically 3% host fee on Airbnb), so the operator nets only 83-85% of the cleaning fee charged
2. For short stays near the minimum, the cleaning fee relative to nightly rate makes the listing less competitive
3. There is a real net cost to the operator even after guest reimbursement

I understand that cleaning costs may be considered embedded in the management fee at some companies, but at 18% management, the management company is not eating $700-$1,000/month in cleaning costs. Those are typically separate.

---

### Finding 5: Natiivo Min-Stay Penalty Not Visible in Revenue Adjustments

**Severity: Important**

The compliance section correctly identifies the 3-night HOA minimum stay. The Sprint 2 fixes claim to implement a -5% OCC / -5% ADR penalty for 3-night minimums. However, examining the revenue computation:

- Base ADR from market API: $342.97
- STR building boost (adr_multiplier 1.06): $363.55
- Final base ADR: $375.24

There is no visible -5% ADR penalty applied. If it were applied to the adjusted $363.55, the result should be ~$345.37, not $375.24. The additional $11.69 gap between $363.55 and $375.24 appears to be event premium baked into the annual average, but no min-stay penalty is deducted.

Similarly for occupancy:
- Base occupancy from market API: 73.79%
- STR building boost (occ_multiplier 1.05): 77.48%
- A -5% penalty should yield ~73.6%, but the final base occupancy is 78.9%

The min-stay penalty does not appear to be applied to this specific report despite the compliance section flagging the 3-night restriction.

**Operator Assessment**: A 3-night minimum for a downtown Miami 1BD is operationally significant. It eliminates the lucrative Friday-Sunday 2-night segment. From my experience, the occupancy hit is 5-10pp, which would bring the modeled 78.9% down to 69-74%. Combined with the missing HOA and cleaning costs, this property is almost certainly cash-flow negative at asking price.

---

### Finding 6: Brickell Bay ADR of $275 is Low for a 3BD in Brickell -- But Occupancy Problem is the Real Issue

**Severity: Nice-to-have**

The Brickell comps in the report show a wide range:
- ADRs: $859.30, $630.80, $575.70, $532.10, $468.70...
- Occupancies: 66%, 87.9%, 93.4%, 91%, 84.1%...

These comps suggest that 3BD units in Brickell can command $500-$600+ ADR with 70-90% occupancy. Yet the model produces $275 ADR at 44.7% occupancy. The model appears to be heavily discounting this property, possibly due to the building classification as "str_friendly" rather than "purpose_built_str."

While the NO-GO verdict is correct regardless (even at $500 ADR and 70% OCC, the debt service on $1.1M would be challenging), the model's revenue projection seems anomalously low compared to the comp data it has access to. An operator looking at this report would question whether the model is broken for this property.

---

### Finding 7: Orlando Seasonality Pattern Concerns

**Severity: Nice-to-have**

The Orlando (Vista Cay) property -- a resort community near theme parks -- shows its seasonality peak in July (+10% ADR, +6% OCC) and trough in September (-17% ADR, -9% OCC). This is directionally correct for Orlando tourism.

However, the base occupancy of 52.3% seems low for a 3BD in Vista Cay, which is a well-known STR community near Universal and the convention center. Vista Cay 3BD units on AirDNA/AirROI typically show 55-65% occupancy with $200-$280 ADR. The model's $248 ADR is in range, but the 52.3% occupancy is on the low side of what I'd expect.

That said, the NO-GO verdict is correct either way -- even bumping occupancy to 65% at $248 ADR yields ~$58.8K revenue against $37.4K debt service plus expenses, still negative.

---

## Property-by-Property Operational Assessment

### Natiivo (CAUTION) -- My Assessment: Should Be NO-GO

| Metric | Model Says | Operator Reality |
|--------|-----------|-----------------|
| Base ADR | $375 | $340-$375 (plausible if min-stay penalty applied) |
| Base Occupancy | 78.9% | 68-73% (after min-stay + realistic expectations) |
| Monthly OpEx | $4,239 | $5,700-$6,500 (add HOA $1,000 + cleaning $800) |
| Monthly Cash Flow | +$1,723 | -$200 to -$1,200 (negative after corrections) |
| Verdict | CAUTION | NO-GO at asking price |

The Natiivo deal only works if: (a) HOA fees really are $0 (they are not), (b) cleaning is free (it is not), and (c) you can sustain 79% occupancy with a 3-night minimum (unlikely). At a purchase price of $490K-$510K with self-management, this could be a marginal deal. At $610K with professional management, it is not viable.

### Vista Cay Orlando (NO-GO) -- My Assessment: Correct NO-GO

The model correctly identifies this as a loser. Negative $24K/year cash flow, DSCR 0.36x, negative even in the optimistic scenario. Vista Cay is a decent STR community but $625K for a 3BD is overpriced for the achievable revenue. Even adding the missing HOA ($500/mo = $6K/yr), the deal was already so far negative it does not change the verdict.

### Brickell Bay (NO-GO) -- My Assessment: Correct NO-GO

This is the clearest NO-GO of the three. At $1.1M with $5,489/mo debt service, the property would need to generate $9,050/mo just to cover debt + OpEx. The model shows $3,738/mo in revenue -- less than half of what is needed. Even if the model's revenue projection is too low (as the comp data suggests), the debt service burden makes this a mathematical impossibility as an STR.

---

## Summary of Sprint 2 Fixes vs. Sprint 1 Issues

| Sprint 1 Finding | Status in Sprint 2 | Assessment |
|-------------------|---------------------|------------|
| F1: 80% occupancy too aggressive | Improved -- Natiivo now 78.9%, but min-stay penalty not applied | Partially fixed |
| F2: Cleaning costs missing | NOT FIXED | Still absent from all reports |
| F3: ADR + OCC both at top quartile | Improved -- elasticity modeled, but appears inverted | Partially fixed |
| F4: Expense ratio bug (6,424%) | Not checked in Sprint 2 JSON (was in narrative) | Unknown |
| F5: Management fee at 20% | FIXED -- now 18% | Resolved |
| F6: No furnishing CapEx | NOT FIXED | Still not modeled |
| F7: Contradictory risk assessment | FIXED -- NO-GO properties now show appropriate risk warnings | Resolved |
| F8: 3-night min impact underestimated | Partially improved -- penalty exists in code but not applied in report | Partially fixed |
| F9: Off-season cash flow not highlighted | Monthly data available but not surfaced | Unchanged |
| F10: Generic 5-year projections | Not checked | Unknown |
| NEW: HOA fees now $0 (regression) | REGRESSION from Sprint 1 | New blocker |
| NEW: ADR-OCC elasticity inverted | New bug | Important |
| NEW: STR tax still 12% (claimed 14%) | Not actually fixed despite AC-3 PASS claim | Important |

---

## Go / No-Go Recommendation

### CONDITIONAL GO -- with mandatory fixes before Chat MVP launch

The model has improved materially. The verdicts for bad deals (Orlando, Brickell) are now correct and clearly communicated. The variable cost scaling and management fee fixes are real improvements. The risk warning system works.

However, three issues must be addressed before Chat MVP:

1. **HOA fee regression** (blocker): HOA fees showing as $0 for condo properties is a data integrity failure that directly misrepresents profitability. This must be fixed and regression-tested.

2. **ADR-OCC elasticity direction** (important): If the sprint documentation says conservative = ADR-10%/OCC+3%, but the model produces ADR-10%/OCC-8%, either the documentation is wrong or the implementation is wrong. Either way, this needs clarification and correction.

3. **Cleaning cost line item** (important): This is the second sprint where cleaning costs are omitted. For an STR-focused tool, this is a fundamental expense category that operators will immediately flag.

If these three items are fixed, the model reaches a level of operational realism sufficient for an informed Chat MVP user. The remaining nice-to-haves (STR tax precision, furnishing CapEx, Brickell ADR calibration) can be deferred.

---

## Appendix: Key Financial Data Points

### Natiivo (159 NE 6th St #4307)
```
Base Scenario:
  ADR: $375.24 | OCC: 78.9% | Revenue: $108,070/yr ($9,006/mo)
  OpEx: $50,871/yr ($4,239/mo) | Debt Service: $36,525/yr ($3,044/mo)
  NOI: $57,199 | Net Cash Flow: +$20,674/yr (+$1,723/mo)
  Cap Rate: 9.4% | CoC: 12.1% | DSCR: 1.57x

Expense Breakdown (monthly):
  HOA: $0 | Prop Tax: $452 | HO6 Insurance: $156 | Liability: $67
  Management (18%): $1,621 | Utilities: $354 | Maintenance: $508
  STR Tax (12%): $1,081

Missing: HOA (~$1,000), Cleaning (~$900), OTA commissions (if not in mgmt fee)
```

### Orlando (5049 Shoreway Loop #10301)
```
Base Scenario:
  ADR: $247.95 | OCC: 52.3% | Revenue: $47,358/yr ($3,947/mo)
  OpEx: $33,909/yr ($2,826/mo) | Debt Service: $37,423/yr ($3,119/mo)
  NOI: $13,449 | Net Cash Flow: -$23,974/yr (-$1,998/mo)
  Cap Rate: 2.2% | CoC: -13.7% | DSCR: 0.36x

Verdict: NO-GO (correct)
```

### Brickell (1200 Brickell Bay Dr #2202)
```
Base Scenario:
  ADR: $275.17 | OCC: 44.7% | Revenue: $44,853/yr ($3,738/mo)
  OpEx: $42,735/yr ($3,561/mo) | Debt Service: $65,865/yr ($5,489/mo)
  NOI: $2,118 | Net Cash Flow: -$63,747/yr (-$5,312/mo)
  Cap Rate: 0.2% | CoC: -20.7% | DSCR: 0.03x

Verdict: NO-GO (correct)
```
