module ExampleHelper
  def passed_example
    base_example { expect(true).to be true }
  end

  def failed_example
    example = base_example { expect(true).to be false }
    example.exception.backtrace.push ':in step:0 `'
    example
  end

  def pending_example
    if ::RSpec::Version::STRING >= '2.99.0'
      base_example { skip('No such step(0): ') }
    else
      base_example { pending('No such step(0): ') }
    end
  end

  def invalid_pending_example
    if ::RSpec::Version::STRING >= '2.99.0'
      base_example { skip('Pending') }
    else
      base_example { pending('Pending') }
    end
  end

  private

    def base_example(&assertion)
      group = ::RSpec::Core::ExampleGroup.describe('Feature').describe('Scenario')
      example = group.example('example', example_metadata, &assertion)
      example.metadata[:file_path] = '/path/to/hoge.feature'
      group.run(NoopObject.new)
      example
    end

    def example_metadata
      {
        turnip_formatter: {
          steps: [ { name: 'Step 1', extra_args: [], keyword: 'When' } ],
          tags: []
        }
      }
    end
end
