require 'test/unit'

class TC_XObject < Test::Unit::TestCase

  def setup
    @n2 = Graphics::FormXObject.new
    @n2.Type=Origami::Name.new("XObject")
    @n2.Resources = Resources.new
    @n2.Resources.ProcSet = [Origami::Name.new("Text"), Origami::Name.new("PDF"), Origami::Name.new("ImageB"), Origami::Name.new("ImageC")]
    @n2.set_indirect(true)
    @n2.BBox = [ 0, 0, 500, 100 ]
    @n2.FormType = 1
  end

  # There was a problem with nil instructions making it into the instruction array.
  # This would prevent rendering instructions from making it into the object stream at save time.
  def test_color_defaults
    @n2.write("test this text", {:x => 300, :y => 100, :size => 10})
    # There should be no nil in this collection as a result of using the default colors
    @n2.instructions.each do |i|
      assert_not_nil i, "Nil instruction found"
    end
  end

  def test_fill_color_specified
    @n2.write("test this text", {:x => 300, :y => 100, :size => 10, :color => 0.5})
    # There should be no nil in this collection
    g_found = false
    @n2.instructions.each do |i|
      assert_not_nil i, "Nil instruction found"
      g_found = true if i.to_s == "0.5 g\n"
    end
    # A g operator should have been found
    assert_true(g_found)
  end

  def test_stroke_color_specified
    @n2.write("test this text", {:x => 300, :y => 100, :size => 10, :stroke_color => 0.5})
    # There should be no nil in this collection
    g_found = false
    @n2.instructions.each do |i|
      assert_not_nil i, "Nil instruction found"
      g_found = true if i.to_s == "0.5 G\n"
    end
    # A g operator should have been found
    assert_true(g_found)
  end

end