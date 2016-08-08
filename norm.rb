#
# https://gist.github.com/gareth/1349891
#
# Code adapted from http://bytes.com/topic/c-sharp/answers/240995-normal-distribution#post980230
module Norm

	def self.normdist x, mean, std, cumulative
		if cumulative
			phi_around x, mean, std
		else
			tmp = 1/((Math.sqrt(2*Math::PI)*std))
			tmp * Math.exp(-0.5 * ((x-mean)/std ** 2))
		end
	end

	# fractional error less than 1.2 * 10 ^ -7.
	def self.erf z
		t = 1.0 / (1.0 + 0.5 * z.abs);

		# use Horner's method
		ans = 1 - t * Math.exp( -z*z - 1.26551223 +
		t * ( 1.00002368 +
		t * ( 0.37409196 +
		t * ( 0.09678418 +
		t * (-0.18628806 +
		t * ( 0.27886807 +
		t * (-1.13520398 +
		t * ( 1.48851587 +
		t * (-0.82215223 +
		t * ( 0.17087277))))))))))
		z >= 0 ? ans : -ans
	end

	# cumulative normal distribution
	def self.phi z
		return 0.5 * (1.0 + erf(z / (Math.sqrt(2.0))));
	end

	# cumulative normal distribution with mean mu and std deviation sigma
	def self.phi_around z, mu, sigma
		return phi((z - mu) / sigma);
	end

	def self.inv(probability, mu, sigma )
		x = p = 0.0
		c0 = c1 = c2 = 0.0
		d1 = d2 = d3 = 0.0
		t = q = 0.0
		q = probability

		if (q == 0.5)
			mu
		else
			q = 1.0 - q

			if ((q > 0) && (q < 0.5))
				p = q
			else
				if (q == 1)
					p = 1 - 0.9999999 # JPR - attempt to fix divide by zero
					# below, what is NormInv(1,x,y)?
				else
					p = 1.0 - q
				end
			end

			t = Math.sqrt(Math.log(1.0 / (p * p)))

			c0 = 2.515517
			c1 = 0.802853
			c2 = 0.010328

			d1 = 1.432788
			d2 = 0.189269
			d3 = 0.001308

			x = t - (c0 + c1 * t + c2 * (t * t)) / (1.0 + d1 * t + d2 * (t * t) + d3 * (t * 3))

			if (q > 0.5)
				x = -1.0 * x
			end
		end

		x * sigma + mu
	end

end
