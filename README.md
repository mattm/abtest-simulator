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

# Contact

If you have any suggestions, find a bug, or just want to say hey drop me a note at [@mhmazur](https://twitter.com/mhmazur) on Twitter or by email at matthew.h.mazur@gmail.com.

# License

MIT © [Matt Mazur](http://mattmazur.com)
