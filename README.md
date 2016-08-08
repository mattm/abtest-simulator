# A/B Test Simulator

A Ruby script for measuing how various A/B test strategies perform.

## Development

In `abtest-simulator.rb`, configure these two constants:

```
ORIGINAL_CONVERSION_RATE = 0.1
VARIATION_OUTCOMES = [-0.2, 0.2]
```

The first is what the current conversion rate is (10% in this example) and the second is how you expect your A/B test to perform (+20% of -20% in this case).

To experiment with the criteria used to declare a winner, modify the `evaluate` method farther down in the file. For example, to end a test as soon as significance is reached, you can use:

```
return "pass" if total_participants >= 10000

if gaussian?(participants_a, conversions_a) && gaussian?(participants_b, conversions_b)
	if p_value(participants_a, conversions_a, participants_b, conversions_b) >= 0.99
		return "yes"
	end
end
```

The first line is necessary because there many be tests that never reach significance, but you still want to end the test at some point. The second part determines the probability of one sample proportion being greater than another and ends the test if it exceeds 0.99.

To execute the script, run:

`ruby abtest-similator.rb`

Which will output the results:

```
Summary:
Passes: 74
Correct: 908
Incorrect: 18
Correct Decisions: 908/926: 98.06%
```

# Debugging

To view the results of a single test, do the following:

1. Change `SIMULATIONS` to 1 (or more if you want to see the results of more than 1 test).

2. Change `DEBUG` to `true`.

This will output

```
Control: 0.1, Variation Actual: 0.08

Results #1:
Control: 15/98 = 0.153 (actual conversion rate: 0.1)
Variation: 5/98 = 0.051 (actual conversion rate: 0.08, actual change: -0.2)
Observed winner: control
P Value: 0.99
Correct Decision

Summary:
Passes: 0
Correct: 1
Incorrect: 0
Correct Decisions: 1/1: 100.0%
```

# Contact

If you have any suggestions, find a bug, or just want to say hey drop me a note at [@mhmazur](https://twitter.com/mhmazur) on Twitter or by email at matthew.h.mazur@gmail.com.

# License

MIT © [Matt Mazur](http://mattmazur.com)
