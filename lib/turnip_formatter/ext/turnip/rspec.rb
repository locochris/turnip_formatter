# -*- coding: utf-8 -*-

require 'turnip/rspec'

module Turnip
  module RSpec
    module Execute
      def run_step(feature_file, step, index)
        example = Turnip::RSpec.fetch_current_example(self)

        begin
          step(step)
        rescue Turnip::Pending => e
          example.metadata[:line_number] = step.line
          example.metadata[:location] = "#{example.metadata[:file_path]}:#{step.line}"

          if ::RSpec::Version::STRING >= '2.99.0'
            skip("No such step(#{index}): '#{e}'")
          else
            pending("No such step(#{index}): '#{e}'")
          end
        rescue StandardError, ::RSpec::Expectations::ExpectationNotMetError => e
          example.metadata[:line_number] = step.line
          e.backtrace.push "#{feature_file}:#{step.line}:in step:#{index} `#{step.description}'"
          raise e
        end
      end

      def push_scenario_metadata(scenario)
        example = Turnip::RSpec.fetch_current_example(self)

        steps = scenario.steps
        example.metadata[:turnip_formatter].tap do |turnip|
          steps.each do |step|
            turnip[:steps] << {
              name: step.description,
              extra_args: step.extra_args,
              keyword: step.keyword
            }
          end
          turnip[:tags] += scenario.tags if scenario.respond_to?(:tags)
        end
      end
    end

    class << self
      def run(feature_file)
        Turnip::Builder.build(feature_file).features.each do |feature|
          ::RSpec.describe feature.name, feature.metadata_hash do
            let(:backgrounds) do
              feature.backgrounds
            end

            let(:background_steps) do
              backgrounds.map(&:steps).flatten
            end

            before do
              example = Turnip::RSpec.fetch_current_example(self)

              example.metadata[:file_path] = feature_file
              example.metadata[:turnip_formatter] = {
                steps: [], tags: feature.tags
              }

              backgrounds.each do |background|
                push_scenario_metadata(background)
              end

              background_steps.each.with_index do |step, index|
                run_step(feature_file, step, index)
              end
            end

            feature.scenarios.each do |scenario|
              instance_eval <<-EOS, feature_file, scenario.line
                describe scenario.name, scenario.metadata_hash do
                  before do
                    push_scenario_metadata(scenario)
                  end

                  it scenario.steps.map(&:description).join(' -> ') do
                    scenario.steps.each.with_index(background_steps.size) do |step, index|
                      run_step(feature_file, step, index)
                    end
                  end
                end
              EOS
            end
          end
        end
      end
    end
  end
end
