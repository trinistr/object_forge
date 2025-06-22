# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :change, :not_change
RSpec::Matchers.define_negated_matcher :include, :exclude
RSpec::Matchers.define_negated_matcher :match, :not_match
RSpec::Matchers.define_negated_matcher :raise_error, :not_raise_error
