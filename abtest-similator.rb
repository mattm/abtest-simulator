require './norm'

module ABTestSimulator

	# Adjust these variables
	ORIGINAL_CONVERSION_RATE = 0.1
	VARIATION_OUTCOMES = [-0.2, 0.2]

	# The # of times to simulate your testing strategy before averging the results
	# The higher the number the more accurate the results will be, but the longer the script will take to run
	SIMULATIONS = 1000

	# Whether or not to output the status of the script as it runs
	# You'll probably want to set the # of simulations to 1 when turning this on
	DEBUG = false

	def self.run
		correct_decisions = incorrect_decisions = passed_decisions = 0

		1.upto(SIMULATIONS).each do |simulation|

			# At the start of each series of A/B tests, we need to reset the control's conversion rate
			control_conversion_rate = ORIGINAL_CONVERSION_RATE

			# We randomly choose an A/B test outcome to determine what the variation's true conversion rate is
			true_variation_change = VARIATION_OUTCOMES.sample

			# Account for situations where the conversion rate would exceed 100%
			if control_conversion_rate * (1 + true_variation_change) > 1
				true_variation_change = 0
				variation_conversion_rate = 1
			else
				variation_conversion_rate = control_conversion_rate * (1 + true_variation_change)
			end

			status "Control: #{control_conversion_rate.round(2)}, Variation Actual: #{variation_conversion_rate.round(2)}"
			control_participants = variation_participants = control_conversions = variation_conversions = 0

			# Simulate visitors participating in the A/B test
			begin

				# Each visitor is assigned either the control or the variation
				# We keep track of the participants and conversions along the way
				if rand < 0.5
					control_participants += 1
					control_conversions += 1 if rand <= control_conversion_rate
				else
					variation_participants += 1
					variation_conversions += 1 if rand <= variation_conversion_rate
				end

				result = evaluate(control_participants, control_conversions, variation_participants, variation_conversions)
			end until result == "yes" || result == "pass"

			if result == "pass"
				passed_decisions += 1
			else

				# At the end of the time period, we check out the results
				observed_control_conversion_rate = control_conversions.to_f / control_participants.to_f
				observed_variation_conversion_rate = variation_conversions.to_f / variation_participants.to_f

				if observed_control_conversion_rate == observed_variation_conversion_rate
					winner = "tie"
				elsif observed_control_conversion_rate > observed_variation_conversion_rate
					winner = "control"
				else
					winner = "variation"
				end

				status "\nResults ##{simulation}:"
				status "Control: #{control_conversions}/#{control_participants} = #{observed_control_conversion_rate.round(3)} (actual conversion rate: #{control_conversion_rate.round(3)})"
				status "Variation: #{variation_conversions}/#{variation_participants} = #{observed_variation_conversion_rate.round(3)} (actual conversion rate: #{variation_conversion_rate.round(3)}, actual change: #{true_variation_change})"
				status "Observed winner: #{winner}"
				status "P Value: " + p_value(control_participants, control_conversions, variation_participants, variation_conversions).round(2).to_s

				# How'd we do?
				if winner == "tie" || true_variation_change == 0 || (winner == "variation" && true_variation_change > 0) || (winner == "control" && true_variation_change < 0)
					status "Correct Decision"
					correct_decisions += 1
				else
					status "Incorrect Decision"
					incorrect_decisions += 1
				end
			end
		end

		puts "\nSummary:"
		puts "Passes: #{passed_decisions}"
		puts "Correct: #{correct_decisions}"
		puts "Incorrect: #{incorrect_decisions}"
		puts "Correct Decisions: #{correct_decisions}/#{correct_decisions + incorrect_decisions}: #{percentage(correct_decisions, correct_decisions + incorrect_decisions)}"
	end

	#
	# Outputs a status message to the console
	def self.status(msg)
		puts msg if DEBUG
	end

	#
	# Returns a percentage given a numerator and denominator
	def self.percentage(n, d)
		if d == 0
			'N/A'
		else
			((n.to_f / d.to_f) * 100.0).round(2).to_s + '%'
		end
	end

	# Given the performance of two variations, this returns
	# 1) "yes" - There is a winner
	# 2) "no" - There is not a winner (yet)
	# 3) "pass" - The criteria to declare a winner was never met
	def self.evaluate(participants_a, conversions_a, participants_b, conversions_b)
		total_participants = participants_a + participants_b

		# When the significance exceeds some amount:

		return "pass" if total_participants >= 10000

		if gaussian?(participants_a, conversions_a) && gaussian?(participants_b, conversions_b)
			if p_value(participants_a, conversions_a, participants_b, conversions_b) >= 0.99
				return "yes"
			end
		end

		# When one of the conversions exceeds some amount:
		# return "yes" if [conversions_a, conversions_b].max >= 100

		# When the total number of conversions exceeds some amount:
		# return "yes" conversions_a + conversions_b >= 100

		# Leave this in place for situations where the none of the criteria above are met
		return "no"
	end

	#
	# Determines the probability that one variation's conversion rate is greather than another's
	# For example p_value(500, 200, 500, 220) = 0.9
	# See: http://www.abtestcalculator.com/
	def self.p_value(participants_a, converisons_a, participants_b, converisons_b)
		p1 = converisons_a.to_f / participants_a.to_f
		se1 = Math.sqrt((p1 * (1 - p1)) / participants_a)

		p2 = converisons_b.to_f / participants_b.to_f
		se2 = Math.sqrt((p2 * (1 - p2)) / participants_b)

		zscore = (p2 - p1) / Math.sqrt(se1 ** 2 + se2 ** 2)

		significance = Norm.normdist(zscore, 0, 1, true)

		[significance, 1 - significance].max
	end

	#
	# Returns whether we can use a Gaussian distribution to approximate the conversion rate distribution
	def self.gaussian?(participants, conversions)
		return false unless conversions > 0

		conversion_rate = conversions.to_f / participants.to_f
		np = participants * conversion_rate
		nq = participants * (1 - conversion_rate)

		participants >= 30 && np >= 5 && nq >= 5
	end
end

ABTestSimulator.run
