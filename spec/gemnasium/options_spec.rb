require 'spec_helper'

describe Gemnasium::Options do
  describe 'parse' do
    context 'without options' do
      it 'does not parse any option' do
        options, parser = Gemnasium::Options.parse []
        expect(options).to be_empty
        expect(parser).to be_kind_of OptionParser
      end
    end

    context 'with version options' do
      it 'understands short version' do
        options, parser = Gemnasium::Options.parse ['-v']
        expect(options).to eql({ show_version: true })
      end

      it 'understands long version' do
        options, parser = Gemnasium::Options.parse ['--version']
        expect(options).to eql({ show_version: true })
      end
    end

    context 'with help options' do
      it 'understands short version' do
        options, parser = Gemnasium::Options.parse ['-h']
        expect(options).to eql({ show_help: true })
      end

      it 'understands long version' do
        options, parser = Gemnasium::Options.parse ['--help']
        expect(options).to eql({ show_help: true })
      end
    end

    context 'with multiple options' do
      it 'understands concatenated options' do
        options, parser = Gemnasium::Options.parse ['-hv']
        expect(options).to eql({ show_help: true, show_version: true })
      end

      it 'understands separated options' do
        options, parser = Gemnasium::Options.parse ['-v', '--help']
        expect(options).to eql({ show_help: true, show_version: true })
      end
    end

    context 'with unsupported option' do
      it 'raises an error' do
        expect { Gemnasium::Options.parse ['--foo'] }.to raise_error OptionParser::ParseError
      end
    end

    context 'with unsupported subcommand' do
      it 'raises an error' do
        expect { Gemnasium::Options.parse ['hack'] }.to raise_error OptionParser::ParseError
      end
    end

    context 'with unsupported option for a valid subcommand' do
      it 'raises an error' do
        expect { Gemnasium::Options.parse ['install', '--foo'] }.to raise_error OptionParser::ParseError
      end
    end

    context 'with valid subcommand' do
      context '`create`' do
        context 'with no options' do
          it 'correctly set the options' do
            options, parser = Gemnasium::Options.parse ['create']
            expect(options).to eql({ command: 'create' })
          end
        end
      end

      context '`install`' do
        context 'with no options' do
          it 'correctly set the options' do
            options, parser = Gemnasium::Options.parse ['install']
            expect(options).to eql({ command: 'install' })
          end
        end

        context 'with rake option' do
          it 'correctly set the options' do
            options, parser = Gemnasium::Options.parse ['install', '--rake']
            expect(options).to eql({ command: 'install', install_rake_task: true })
          end
        end
      end

      context '`push`' do
        context 'with no options' do
          it 'correctly set the options' do
            options, parser = Gemnasium::Options.parse ['push']
            expect(options).to eql({ command: 'push' })
          end
        end
      end
    end
  end
end
