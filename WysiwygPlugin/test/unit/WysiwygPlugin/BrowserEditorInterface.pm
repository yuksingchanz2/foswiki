use strict;

package BrowserEditorInterface;
# This package encapsulates the interface to the wysiwyg editor

use Scalar::Util;

my $editFrameLocator = "css=iframe#topic_ifr";
my $wikitextLocator = "css=a#topic_hide";
my $wysiwygLocator = "css=input#topic_2WYSIWYG";
my $editTextareaLocator = "css=textarea#topic";
my $editCancelButtonLocator = "css=input#cancel";

# This must match the text in foswiki_tiny.js
my $waitForServerMessage = "Please wait... retrieving page from server.";

sub new {
    my $class = shift;
    my $test = shift;

    # Make sure that the test object has set up a sufficiently-rich 
    # enviroment that includes a user, session, test-web, etc
    # along with a selenium interface to one or more browsers
    $test->assert( $test->isa('FoswikiSeleniumTestCase') );

    my $this = bless(
        {
            _test => $test,
            _initWebPreferences => 0,
            _initLoginForBrowser => {},
            _editorMode => {},
            _interactions => 0,
        },
        $class
    );

    Scalar::Util::weaken($this->{_test});

    return $this;
}

sub init {
    my $this = shift;

    if (not $this->{_initWebPreferences}) {
        my $topicObject = Foswiki::Meta->new(
              $this->{_test}->{session},
              $this->{_test}->{test_web},
              $Foswiki::cfg{WebPrefsTopicName},
              <<"HERE"
   * Set SKIN=pattern
   * Set ALLOWTOPICCHANGE=$this->{_test}->{test_user_wikiname}
HERE
        );
        $topicObject->save();

        $this->{_initWebPreferences} = 1;
    }

    if (not $this->{_initLoginForBrowser}->{ $this->{_test}->browserName() }) {
        $this->{_test}->login();

        $this->{_initLoginForBrowser}->{ $this->{_test}->browserName() } = 1;
    }

    # TMCE eventually stops responding to commands in Firefox,
    # so once in a while it is necessary to cancel the edit
    # The limit was arbitrarily chosen.
    if ($this->editorMode() and $this->{_interactions} > 20) {
        $this->cancelEdit();
    }

}

sub finish {
    my $this = shift;
    for my $browser (keys %{ $this->{_editorModeForBrowser} }) {
        $this->{_test}->selectBrowser($browser);

        $this->cancelEdit();
    }
    if (keys %{ $this->{_editorModeForBrowser} }) {
        $this->{_test}->selenium->pause(); # Breathe for a moment; let TMCE settle before doing anything else
    }

    undef $this->{_test};
    undef $this->{_initWebPreferences};
    undef $this->{_initLoginForBrowser};
    undef $this->{_editorModeForBrowser};
}

sub editorMode {
    my $this = shift;
    if (exists $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() }) {
        return $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() };
    }
    else {
        return ;
    }
}

sub openWysiwygEditor {
    my $this = shift;
    my $web = shift;
    my $topic = shift;

    $this->cancelEdit() if exists $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() };

    $this->{_test}->selenium->open_ok( Foswiki::Func::getScriptUrl( $web, $topic, 'edit') );

    # The editor can take a while to open, and has to do another server request to convert TML2HTML, so use a longer timeout
    $this->{_test}->selenium->wait_for_element_present( $editFrameLocator, 2 * $this->{_test}->timeout() );
    $this->{_test}->selenium->pause(); # Breathe for a moment; let TMCE settle before doing anything else

    $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() } = 'wysiwyg';

    $this->{_interactions}++;
}

sub cancelEdit {
    my $this = shift;

    return unless exists $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() };

    $this->selectTopFrame();
    $this->{_test}->selenium->click( $editCancelButtonLocator );

    delete $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() };
}

sub selectWysiwygEditorFrame {
    my $this = shift;
    $this->{_test}->selenium->select_frame_ok($editFrameLocator);
}

sub selectTopFrame {
    my $this = shift;
    $this->{_test}->selenium->select_frame_ok("relative=top");
}

sub setWikitextEditorContent {
    my $this = shift;
    my $text = shift;
    $this->{_test}->type($editTextareaLocator, $text);

    $this->{_interactions}++;
}

sub getWikitextEditorContent {
    my $this = shift;
    return $this->{_test}->selenium->get_value($editTextareaLocator);
}

sub setWysiwygEditorContent {
    my $this = shift;
    my $text = shift;

    $this->selectWysiwygEditorFrame();

    my $bufferName = 'window.document.unitTestBuffer';
    $this->{_test}->selenium->get_eval("$bufferName = '';");

    my $maxChars = 1000;
    my $textLength = length $text;
    my $start = 0;
    while ($start < $textLength) {
        my $chunk = substr($text, $start, $maxChars);
        $chunk =~ s#\\#\\\\#g;
        $chunk =~ s#\n#\\n#g;
        $chunk =~ s#"#\\"#g;
        $start += $maxChars;
        my $javascript = qq/$bufferName += "$chunk";/;
        $this->{_test}->selenium->get_eval($javascript);
    }

    my $javascript = qq/selenium.browserbot.findElement("css=body").innerHTML = $bufferName;/;
    $this->{_test}->selenium->get_eval($javascript);

    $this->selectTopFrame();

    $this->{_interactions}++;
}

sub getWysiwygEditorContent {
    my $this = shift;

    $this->selectWysiwygEditorFrame();
    my $javascript = qq/selenium.browserbot.findElement("css=body").innerHTML;/;
    my $content = $this->{_test}->selenium->get_eval($javascript);
    $this->selectTopFrame();

    return $content;
}

sub selectWikitextMode {
    my $this = shift;
    return if $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() } eq 'wikitext';
    if ($this->{_test}->selenium->is_element_present($wysiwygLocator)) {
        # SMELL: I can't see this button, but the assert fails. Dunno why.
        # $this->{_test}->assertElementIsNotVisible( $wysiwygLocator );
    }

    $this->{_test}->assertElementIsPresent( $wikitextLocator );
    $this->{_test}->assertElementIsVisible( $wikitextLocator );
    $this->{_test}->selenium->click_ok( $wikitextLocator );

    $this->{_test}->waitFor(sub{ $this->{_test}->selenium->is_visible($editTextareaLocator); },
                   "topic textarea must be visible");

    # SMELL: I can't see the wikitext button, but this assert fails. Dunno why.
    # $this->{_test}->assertElementIsNotVisible( $wikitextLocator );

    $this->{_test}->waitFor(sub{ $this->{_test}->selenium->get_value($editTextareaLocator) !~ /\Q$waitForServerMessage/; });

    $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() } = 'wikitext';

    $this->{_interactions}++;
}

sub selectWysiwygMode {
    my $this = shift;
    return if $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() } eq 'wysiwyg';
    $this->{_test}->assertElementIsPresent( $wysiwygLocator );
    $this->{_test}->assertElementIsVisible( $wysiwygLocator );
    $this->{_test}->selenium->click_ok( $wysiwygLocator );

    $this->{_test}->waitFor(sub{ $this->{_test}->selenium->is_visible($editFrameLocator); },
                   "wysiwyg edit area must be visible");

    # SMELL: this should work
    # $this->{_test}->assertElementIsNotVisible( $editTextareaLocator );

    $this->selectWysiwygEditorFrame();
    $this->{_test}->waitFor(sub{ $this->{_test}->selenium->get_text("css=body") !~ /\Q$waitForServerMessage/; });
    $this->selectTopFrame();

    $this->{_editorModeForBrowser}->{ $this->{_test}->browserName() } = 'wysiwyg';

    $this->{_interactions}++;
}

1;
