require 'test/unit'
require 'stringio'

class TC_PdfSigAppearance < Test::Unit::TestCase

  def setup
    @target = PDF.read("test/dataset/calc.pdf", :ignore_errors => false, :verbosity => Parser::VERBOSE_QUIET)
    @output = StringIO.new

    @cert = OpenSSL::X509::Certificate.new(File.read("test/dataset/test.dummycrt"))
    @key = OpenSSL::PKey::RSA.new(File.read("test/dataset/test.dummykey"))
  end

  # def teardown
  # end

  def test_sig

    box = { x: 75, y:180, width: 500, height: 125 }

    signedby = "Anyco Inc"
    location = "USA"
    contact = "John Doe"
    reason = "Testing it"
    date = Time.now

    caption="Digitally Signed By: #{signedby}\nContact: #{contact}\nLocation: #{location}\nReason: #{reason}\nDate: #{date} "

    n0 = Graphics::FormXObject.new
    n0.Type=Origami::Name.new("XObject")
    n0.BBox = [ 0, 0, box[:width], box[:height] ]
    n0.set_indirect(true)
    n0.Resources = Resources.new
    n0.Resources.ProcSet = [Origami::Name.new("Text")]
    n0.FormType = 1
    n0.draw_dsblank

    n2 = Graphics::FormXObject.new
    n2.Type=Origami::Name.new("XObject")
    n2.Resources = Resources.new
    n2.Resources.ProcSet = [Origami::Name.new("Text")]
    n2.set_indirect(true)
    n2.BBox = [ 0, 0, box[:width], box[:height] ]
    n2.FormType = 1
    n2.write(caption,:x => 300, :y => 100, :size => 10)

    signature = Origami::Graphics::ImageXObject.from_image_file('test/dataset/sig.jpg', 'jpg')
# Load stamp and add reference to the page
    signature_options = {
        :scale => {x: 144, y: 70} # Scale width to be 2 inches, for grins.  Default PDF user space is 72 units per inch.
    }
    signature.Width = 596
    signature.Height = 289
    signature.ColorSpace = Origami::Graphics::Color::Space::DEVICE_GRAY
    signature.BitsPerComponent = 8
    signature.Interpolate = true
    n2.Resources.add_xobject(signature, Origami::Name.new("signature"))
    n2.paint_xobject(Origami::Name.new("signature"), signature_options)

##Sets the signature appearance form

    frm = Graphics::FormXObject.new
    frm.Type=Origami::Name.new("XObject")
    frm.set_indirect(true)
    frm.Resources = Resources.new
    frm.Resources.ProcSet = [Origami::Name.new("PDF")]
    frm.FormType = 1
    frm.Resources.add_xobject(n0, Origami::Name.new("n0"))
    frm.Resources.add_xobject(n2, Origami::Name.new("n2"))
    frm.BBox = [ 0, 0, box[:width], box[:height] ]
    frm.paint_xobject(Origami::Name.new("n0"))
    frm.paint_xobject(Origami::Name.new("n2"))

# Set up the appearance dictionary

    apdict = Annotation::AppearanceNDictionary.new
    apdict.set_indirect(true)
    apdict.BBox = [ 0, 0, box[:width], box[:height] ]
    apdict.Resources = Resources.new
    apdict.Resources.ProcSet = [Origami::Name.new("PDF")]
    apdict.Resources.add_xobject(frm, Origami::Name.new("FRM"))
    apdict.paint_xobject(Origami::Name.new("FRM"))

    annot = Annotation::Widget::Signature.new.set_indirect(true)
    annot.Rect = Rectangle[
        :llx => box[:x],
        :lly => box[:y],
        :urx => box[:x] + box[:width],
        :ury => box[:y] + box[:height]
    ]
    annot.F = Annotation::Flags::PRINT #sets the print mode on
    annot.Ff = 0
    annot.T = "Signature1"
    annot.M = Origami::Date.now

    annot.set_normal_appearance(apdict)

    assert_nothing_raised do
      @target.append_page(page = Page.new)
      page.add_annot(annot)

      @target.sign(@cert, @key,
                   :annotation => annot,
                   :location => location,
                   :contact => contact,
                   :reason => reason
      )
    end

    assert @target.frozen?

    assert_nothing_raised do
      @target.save(@output)
    end

    assert PDF.read(@output.reopen(@output.string,'r'), :verbosity => Parser::VERBOSE_QUIET).verify
  end

end

class TC_PdfDrawXObject < Test::Unit::TestCase
  def test_errors
    n2 = Graphics::FormXObject.new
    assert_raises ArgumentError do
      n2.draw_xobject("name", {:translate => { :x => 0 }}) # :y is missing
    end
    assert_raises ArgumentError do
      n2.draw_xobject("name", {:rotate => { :a => 0 }}) # :q is missing
    end
  end

  def test_validity
    n2 = Graphics::FormXObject.new
    assert_nothing_raised do
      n2.draw_xobject("name", {:scale => { :x => 0, :y => 0 }})
    end
  end
end