# publish-to-apple
Publish a Standard Ebooks edition to Apple Books

At it's heart, this is a shell script that takes a [Standard Ebooks](https://github.com/standardebooks/) repository, with or without a built epub, and then converts it into a form where it can be submitted to the Apple Books store. As such, much of it is very specific to the standards and formats that Standard Ebooks uses, but there still may be pieces of it that are of use for other Ebooks.

### Dependencies

This script uses the [Standard Ebooks toolkit](https://github.com/standardebooks/tools), [truncate](https://formulae.brew.sh/formula/truncate), and [iTunes Transporter](https://help.apple.com/itc/transporteruserguide/en.lproj/static.html) as dependencies. It has been tested in a zsh environment on Apple silicon. If you are planning to run this on unrelated epubs, you may find that the Standard Ebooks command extract-ebook is very useful for unpacking the epub file to get access to the metadata and other assets.

### Extracting metadata

Epub metadata is stored in the content.opf file. The bulk of this script is concerned with querying that metadata to extract values and put them in the format that Apple requires. There are some peculiarities here based on the way that Standard Ebooks constructs these files that need to be taken into account.

#### Subjects

Apple requires that submissions have at least one and at most two subject tags; these can use one of five code systems; we're using BISAC as it's easiest to deal with, but also we don't care about classifying our volumes to maximise sales.

If you have any Juvenile codes, you must provide an Interest Age range for the book. You cannot use the most generic BISAC nonfiction subject `NON000000`.

#### Apple vendor ID

The Apple vendor ID must be a unique string of up to 100 characters made only of letters, numbers, underscores, and dashes. While iTunes Producer will create a numeric string for you by default, you can create your own as well. When you submit an updated version of a book, it will amend the old version if and only if the vendor ID matches.


### iTunes Transporter

iTunes Transporter is a command line tool replacement for the GUI [iTunes Producer]
(https://itunespartner.apple.com/books/tools). Contact [Apple Books publisher support](https://itunespartner.apple.com/books/articles/apple-books-support-2701) for issues with this. We recommend ensuring you are able to submit a book with iTunes Producer before testing the process with iTunes Transporter.

#### iTunes password

The password used here must be an app-specific password generated within [your Apple account](https://appleid.apple.com/account/manage).