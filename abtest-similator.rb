module ABTestSimulator

	# Adjust these variables
	VISITORS_PER_DAY = 300
	ORIGINAL_CONVERSION_RATE = 0.1
	VARIATION_OUTCOMES = [-0.1, -0.1, -0.05, 0, 0, 0, 0.05, 0.1, 0.1]

	# The # of times to simulate your testing strategy before averging the results
	# The higher the number the more accurate the results will be, but the longer the script will take to run
	SIMULATIONS = 100

	# Whether or not to output the status of the script as it runs
	# You'll probably want to set the # of simulations to 1 when turning this on
	DEBUG = false

	def self.run
		results = 1.upto(SIMULATIONS).collect do

			# At the start of each series of A/B tests, we need to reset the control's conversion rate
			control_conversion_rate = ORIGINAL_CONVERSION_RATE

			# Run enough tests to cover an entire year
			day = 0
			test_num = 0

			begin

				# We randomly choose an A/B test outcome to determine what the variation's true conversion rate is
				true_variation_change = VARIATION_OUTCOMES.sample

				# Account for situations where the conversion rate would exceed 100%
				if control_conversion_rate * (1 + true_variation_change) > 1
					true_variation_change = 0
					variation_conversion_rate = 1
				else
					variation_conversion_rate = control_conversion_rate * (1 + true_variation_change)
				end

				status "Resetting, #{control_conversion_rate}, #{variation_conversion_rate}"
				control_participants = variation_participants = control_conversions = variation_conversions = 0
				test_num += 1

				status "\nA/B Test ##{test_num}"

				# Then simulate visitors coming to the site each day
				begin
					day += 1
					1.upto(VISITORS_PER_DAY).each do |visitor|

						# Each visitor is assigned either the control or the variation
						# We keep track of the participants and conversions along the way
						if rand < 0.5
							control_participants += 1
							control_conversions += 1 if rand <= control_conversion_rate
						else
							variation_participants += 1
							variation_conversions += 1 if rand <= variation_conversion_rate
						end
					end

					# status "Day: ##{day}: #{control_conversions}, #{variation_conversions}"
					should_stop_test = [control_conversions, variation_conversions].max >= 50
					# should_stop_test = control_participants + variation_participants > 500
				end until should_stop_test

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

				status "Control: #{control_conversions}/#{control_participants} = #{observed_control_conversion_rate.round(3)} (actual conversion rate: #{control_conversion_rate.round(3)})"
				status "Variation: #{variation_conversions}/#{variation_participants} = #{observed_variation_conversion_rate.round(3)} (actual conversion rate: #{variation_conversion_rate.round(3)}, actual change: #{true_variation_change})"
				status "Observed winner: #{winner}"

				# How'd we do?
				if winner == "variation"
					status true_variation_change >= 0 ? 'Good choice' : 'Bad choice'

					# If we chose the variation, make it the new control
					control_conversion_rate = variation_conversion_rate
					status "New conversion rate: #{control_conversion_rate}"
				elsif winner == "control"
					status true_variation_change > 0 ? 'Bad choice' : 'Good choice'
				end
			end until day >= 365

			# After a year, record the final conversion rate change
			simulation_yearly_growth_rate = yearly_growth_rate(control_conversion_rate, day)
			simulation_tests_per_year = (test_num.to_f / day.to_f) * 365
			# puts [ORIGINAL_CONVERSION_RATE, control_conversion_rate, overall_growth_rate, daily_growth_rate, yearly_growth_rate, day, test_num, tests_per_year].join("\t")

			[simulation_yearly_growth_rate, simulation_tests_per_year]
		end

		yearly_growth_rates = results.collect{ |result| result.first }
		avg_yearly_growth_rate = (yearly_growth_rates.inject(0){|sum, x| sum + x }.to_f / yearly_growth_rates.length.to_f) * 100

		tests_per_year = results.collect{ |result| result.last }
		avg_tests_per_year = (tests_per_year.inject(0){|sum, x| sum + x }.to_f / tests_per_year.length.to_f)

		puts avg_yearly_growth_rate.round.to_s + "% per year over #{avg_tests_per_year.round} tests"
	end

	def self.status(msg)
		puts msg if DEBUG
	end

	# Lets say for a particular simulation we started with a conversion rate of 0.1 and the final test runs
	# 380 days have passed and the conversion rate is now 0.14. That works out to an overal growth rate of
	# 0.14/0.1 = 1.4 or +40%. That's for 380 days though, we want 365 days, so we work backwards to figure out
	# the daily growth rate of 0.0885845%, then use that to figure out the 365-day growth rate of +38.15%
	def self.yearly_growth_rate(final_control_conversion_rate, number_of_days)
		overall_growth_rate = final_control_conversion_rate / ORIGINAL_CONVERSION_RATE - 1
		daily_growth_rate = (1 + overall_growth_rate) ** (1.0 / number_of_days.to_f) - 1
		(1.0 + daily_growth_rate) ** 365 - 1.0
	end
end

ABTestSimulator.run
