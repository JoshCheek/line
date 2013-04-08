describe 'integration' do
  it 'is actually all hooked together correctly' do
    bin = File.expand_path '../../bin/line', __FILE__
    `echo 1 | #{bin} 1`.should == "1\n"
  end
end
