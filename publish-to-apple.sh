############################################################
# Help                                                     #
############################################################
Help()
{
	# Display Help
    echo "usage: publish-to-apple [-h] [-r PATH TO REPOSITORY]"
    echo "                        [-e PATH TO BUILT EPUB FILE]"
    echo "                        [-u APPLE USERNAME]"
    echo "                        [-p APPLE APP-SPECIFIC PASSWORD]"
    echo ""
    echo ""
    echo "Take a Standard Ebooks directory, process it into a .itmsp"
    echo "file, and then submit that file to Apple to be available on"
    echo "Apple Books for free in the US. This script calls the"
    echo "StandardEbooks toolkit, truncate, and iTunes Transporter"
    echo "as dependancies."
    echo ""
    echo "required arguments:"
    echo "  -r PATH TO REPOSITORY, --repo PATH TO REPOSITORY"
    echo "                        the full path to a Standard Ebooks"
    echo "                        repository"
    echo ""
    echo "optional arguments:"
    echo "  -h, --help            show this help message and exit"
    echo "  -e PATH TO EPUB, --epub PATH TO EPUB"
    echo "                        the path to a built epub file of the"
    echo "                        repository in question. if not"
    echo "                        provided, the epub will be built as"
    echo "                        part of the process"
    echo "  -u APPLE USERNAME, --username APPLE USERNAME"
    echo "                        the username for the Apple account"
    echo "                        used to submit the book. if not"
    echo "                        provided, the script will save the"
    echo "                        generated .itmsp file to the present"
    echo "                        working directory."
    echo "  -p APPLE PASSWORD, --password APPLE PASSWORD"
    echo "                        the app-specific password for the"
    echo "                        Apple account in question. app-"
    echo "                        specific passwords can be generated"
    echo "                        at appleid.apple.com/account/manage"
    echo 
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

#Check for dependencies
command -v truncate >/dev/null 2>&1 || { 
		echo >&2 "truncate required. Install using brew install truncate."; 
		exit 1; 
	}
command -v se >/dev/null 2>&1 || { 
		echo >&2 "StandardEbooks toolkit required. Install using pipx install standardebooks."; 
		exit 1; 
	}
command -v /usr/local/itms/bin/iTMSTransporter >/dev/null 2>&1 || { 
		echo >&2 "iTunes Transporter required. iTunes Transporter can be downloaded from https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/resources/download/public/Transporter__OSX/bin/."; 
		exit 1; 
	}


# Transform long options to short ones
for arg in "$@"; do
	shift
	case "$arg" in
		'--help')     set -- "$@" '-h'   ;;
		'--repo')     set -- "$@" '-r'   ;;
		'--epub')     set -- "$@" '-e'   ;;
		'--username') set -- "$@" '-u'   ;;
		'--password') set -- "$@" '-p'   ;;
		*)            set -- "$@" "$arg" ;;
  esac
done

# Default behavior
prebuilt_epub=false; run_transporter=true

# Initialise variables
path_to_repo=false; path_to_epub=false; transporter_username=false; transporter_password=false

# Parse short options
OPTIND=1
while getopts "h:r:e:u:p:" opt
do
	case "${opt}" in
		'h') Help; exit 0 ;;
		'r') path_to_repo=${OPTARG};;
		'e') path_to_epub=${OPTARG} && prebuilt_epub=true;;
		'u') transporter_username=${OPTARG};;
		'p') transporter_password=${OPTARG};;
		'?') Help >&2; exit 1 ;;
	esac
done
shift $(expr $OPTIND - 1) # remove options from positional parameters

# Deal with missing inputs
if [[ $transporter_username == false || $transporter_password == false ]]; then
	run_transporter=false
fi
if [[ $path_to_repo == false ]]; then
	echo >&2 "path to repository is required"; exit 1
fi

# echo 'arguments'
# echo 'path_to_repo' $path_to_repo
# echo 'path_to_epub' $path_to_epub
# echo 'transporter_username' $transporter_username
# echo 'transporter_password' $transporter_password
# echo 'run_transporter' $run_transporter
# echo 'prebuilt_epub' $prebuilt_epub


# get pwd
original_directory=$(pwd)

# go to repo, make a temp directory
cd "${path_to_repo}/src/epub"
mkdir "${path_to_repo}/temp"

#define input filenames
content_input="${path_to_repo}/src/epub/content.opf"
cover_filename="${path_to_repo}/images/cover.jpg"

# Define project name, epub filename
se_github=$(xml sel -t -c '//_:meta[@property="se:url.vcs.github"]/text()' "${content_input}")
se_name=${se_github:34}
epub_filename="${se_name}.epub"

# Create output file
itmsp_name="${path_to_repo}/temp/${se_name}.itmsp"
mkdir "$itmsp_name"
metadata_output="${itmsp_name}/metadata.xml"

# if no epub path, build compatible epub to temp folder and set that as path to epub
if [[ $prebuilt_epub == false ]]; then
	se build -o "${path_to_repo}/temp" -v "${path_to_repo}"
	path_to_epub="${path_to_repo}/temp/${epub_filename}"
fi

# Define file hashes
epub_md5=($(md5sum "${path_to_epub}"))
cover_md5=($(md5sum "$cover_filename"))

# Define file sizes
epub_size=$(stat -f%z "${path_to_epub}")
cover_size=$(stat -f%z "$cover_filename")

# Create .docinfo file
touch "${itmsp_name}/.docinfo"
cat << EOF > "${itmsp_name}/.docinfo"
6270 6c69 7374 3030 d401 0203 0405 0607
0a58 2476 6572 7369 6f6e 5924 6172 6368
6976 6572 5424 746f 7058 246f 626a 6563
7473 1200 0186 a05f 100f 4e53 4b65 7965
6441 7263 6869 7665 72d1 0809 5472 6f6f
7480 01a5 0b0c 1516 1755 246e 756c 6cd3
0d0e 0f10 1214 574e 532e 6b65 7973 5a4e
532e 6f62 6a65 6374 7356 2463 6c61 7373
a111 8002 a113 8003 8004 5876 656e 646f
7249 445b 3130 3038 3139 3739 3233 35d2
1819 1a1b 5a24 636c 6173 736e 616d 6558
2463 6c61 7373 6573 5f10 134e 534d 7574
6162 6c65 4469 6374 696f 6e61 7279 a31a
1c1d 5c4e 5344 6963 7469 6f6e 6172 7958
4e53 4f62 6a65 6374 0811 1a24 2932 3749
4c51 5359 5f66 6e79 8082 8486 888a 939f
a4af b8ce d2df 0000 0000 0000 0101 0000
0000 0000 001e 0000 0000 0000 0000 0000
0000 0000 00e8 
EOF
truncate -s -1 "${itmsp_name}/.docinfo"

# Copy over the epub and cover artwork
cp "${path_to_epub}" "${itmsp_name}/${path_to_epub##*/}"
cp "${cover_filename}" "${itmsp_name}/cover.jpg"

# Create vendor id
vendor_id="${se_name//[^a-zA-Z0-9]}"

## Create file, add headers
touch "${metadata_output}"
cat << EOF > "${metadata_output}"
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://apple.com/itunes/importer/publication" version="publication5.0" generator="ITunesPackage" generator_version="3.1.4 (1085)">
    <provider>StandardEbooksL3C</provider>
    <book>
        <vendor_id>StandardEbooks_${vendor_id:0:80}</vendor_id>
        <metadata>
            <publication_type>book</publication_type>
EOF

## Add series
if [[ $(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "count(//opf:meta[@property='belongs-to-collection']/text())" "${content_input}") ]]; then
	collection_count=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "count(//opf:meta[@property='belongs-to-collection']/text())" "${content_input}")
	for i in $(seq 1 $collection_count)
	do
		collection_type=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='collection-type' and @refines='#collection-${i}']/text()" "${content_input}")
		if [[ $collection_type == series ]]; then
			add_series=true
			series_name=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@id='collection-${i}']/text()" "${content_input}")
			series_number=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='group-position' and @refines='#collection-${i}']/text()" "${content_input}")
		else
			add_series=false
		fi
	done
	if [[ $add_series == true ]]; then
cat << EOF >> "${metadata_output}"
            <series_info>
                <series>
                    <title>${series_name}</title>
                    <sequence_number>${series_number}</sequence_number>
                </series>
            </series_info>
EOF
	fi
fi

## Add title
title=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c '//dc:title[1]/text()' "${content_input}")
cat << EOF >> "${metadata_output}"
            <title>$title</title>
EOF

## Add subtitle
if [[ $(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//dc:title[@id='subtitle']/text()" "${content_input}") ]]; then
	subtitle=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//dc:title[@id='subtitle']/text()" "${content_input}")
cat << EOF >> "${metadata_output}"
            <subtitle>$subtitle</subtitle>
EOF
fi


##Start contributors
cat << EOF >> "${metadata_output}"
            <contributors>
EOF

## Add author - NEEDS UPDATING
### Count dc:creator tags
author_count=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "count(//dc:creator)" "${content_input}")
### For each dc:creator, add a primary contributor author tag
for i in $(seq 1 $author_count)
do
author=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//dc:creator[$i]/text()" "${content_input}")
### NEED AUTHOR_SORT_TYPE
author_sort=$(xml sel -t -c '//_:meta[@property="file-as"][@refines="#author"]/text()' "${content_input}")
cat << EOF >> "${metadata_output}"
                <contributor>
                    <primary>true</primary>
                    <name>$author</name>
                    <sort_name>$author_sort</sort_name>
                    <roles>
                        <role>author</role>
                    </roles>
                </contributor>
EOF
done

## Count contributors, loop through them all
contributor_count=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c 'count(//dc:contributor)' "${content_input}")

for i in $(seq 1 $contributor_count)
do
	contributor_name=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//dc:contributor[$i]/text()" "${content_input}")
	se_contributor_type=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "string(//dc:contributor[$i]/@id)" "${content_input}")
	marc_contributor_type=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='role' and @refines='#${se_contributor_type}']/text()" "${content_input}")
	contributor_sort=$(xml sel -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='file-as' and @refines='#${se_contributor_type}']/text()" "${content_input}")

	if [[ $se_contributor_type == producer* ]]; then
		apple_role="prepared for publication by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == aft ]]; then
		apple_role="afterword by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == ann ]]; then
		apple_role="notes by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == art ]]; then
		apple_role="cover design or artwork by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == aui || $marc_contributor_type == win ]]; then
		apple_role="introduction by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == com ]]; then
		apple_role="compiled by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == ctb ]]; then
		apple_role="contributions by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == ctg ]]; then
		apple_role="maps by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == edc || $marc_contributor_type == edt ]]; then
		apple_role="edited by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == ill ]]; then
		apple_role="illustrated by"
		contributor_primary=true
		skip=false
	elif [[ $marc_contributor_type == pht ]]; then
		apple_role="photographs by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == trc ]]; then
		apple_role="prepared for publication by"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == trl ]]; then
		apple_role="translated by"
		contributor_primary=true
		skip=false
	elif [[ $marc_contributor_type == wpr ]]; then
		apple_role="writer of preface"
		contributor_primary=false
		skip=false
	elif [[ $marc_contributor_type == wst ]]; then
		apple_role="supplement by"
		contributor_primary=false
		skip=false
	else
		apple_role="NULL"
		contributor_primary=false
		skip=true
	fi

## Append roles
	if [[ $skip == false ]] ; then
		if [[ $contributor_primary = true ]]; then
cat << EOF >> "${metadata_output}"
                <contributor>
                    <primary>true</primary>
                    <name>$contributor_name</name>
                    <sort_name>$contributor_sort</sort_name>
                    <roles>
                        <role>$apple_role</role>
                    </roles>
                </contributor>
EOF
		else
cat << EOF >> "${metadata_output}"
                <contributor>
                    <name>$contributor_name</name>
                    <sort_name>$contributor_sort</sort_name>
                    <roles>
                        <role>$apple_role</role>
                    </roles>
                </contributor>
EOF
		fi
	fi
done

## Add editor in chief

cat << EOF >> "${metadata_output}"
                <contributor>
                    <name>Alex Cabal</name>
                    <sort_name>Cabal, Alex</sort_name>
                    <roles>
                        <role>editor-in-chief</role>
                    </roles>
                </contributor>
            </contributors>
EOF

## Add language
cat << EOF >> "${metadata_output}"
            <languages>
                <language type="main">eng</language>
            </languages>
EOF

## Add page count
word_count=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='se:word-count']/text()" "${content_input}")
if [[ $(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='se:subject']/text()" "${content_input}") == *Drama* ]]
	then
		page_count=$(echo $(($word_count/180+5)))
	else
		page_count=$(echo $(($word_count/250+5)))
fi
cat << EOF >> "${metadata_output}"
            <number_of_pages>$page_count</number_of_pages>
EOF


## Add subjects
### Count subjects, extract subject list
se_subject_count=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "count(//opf:meta[@property='se:subject']/text())" "${content_input}")
se_subjects=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@property='se:subject']/text()" "${content_input}")

## Get booleans of if each subject is present
if [[ $se_subjects == *Adventure* ]]; then
	subject_adventure=true; else subject_adventure=false; fi
if [[ $se_subjects == *Autobiography* ]]; then
	subject_autobiography=true; else subject_autobiography=false; fi
if [[ $se_subjects == *Biography* ]]; then
	subject_biography=true; else subject_biography=false; fi
if [[ $se_subjects == *Childrens* ]]; then
	subject_childrens=true; else subject_childrens=false; fi
if [[ $se_subjects == *Comedy* ]]; then
	subject_comedy=true; else subject_comedy=false; fi
if [[ $se_subjects == *Drama* ]]; then
	subject_drama=true; else subject_drama=false; fi
if [[ $se_subjects == *Fantasy* ]]; then
	subject_fantasy=true; else subject_fantasy=false; fi
if [[ $se_subjects == *Fiction* ]]; then
	subject_fiction=true; else subject_fiction=false; fi
if [[ $se_subjects == *Horror* ]]; then
	subject_horror=true; else subject_horror=false; fi
if [[ $se_subjects == *Memoir* ]]; then
	subject_memoir=true; else subject_memoir=false; fi
if [[ $se_subjects == *Mystery* ]]; then
	subject_mystery=true; else subject_mystery=false; fi
if [[ $se_subjects == *Philosophy* ]]; then
	subject_philosophy=true; else subject_philosophy=false; fi
if [[ $se_subjects == *Poetry* ]]; then
	subject_poetry=true; else subject_poetry=false; fi
if [[ $se_subjects == *Satire* ]]; then
	subject_satire=true; else subject_satire=false; fi
if [[ $se_subjects == *Science* ]]; then
	subject_scifi=true; else subject_scifi=false; fi
if [[ $se_subjects == *Spirituality* ]]; then
	subject_spirituality=true; else subject_spirituality=false; fi
if [[ $se_subjects == *Travel* ]]; then
	subject_travel=true; else subject_travel=false; fi

## Assign first subject based on booleans in hierarchy
if [[ $subject_drama == true ]]; then bisac_subject_1=DRA000000
elif [[ $subject_poetry == true ]]; then bisac_subject_1=POE000000
elif [[ $subject_memoir == true ]]; then bisac_subject_1=BIO026000
elif [[ $subject_autobiography == true ]]; then bisac_subject_1=BIO026000
elif [[ $subject_biography == true ]]; then bisac_subject_1=BIO000000
elif [[ $subject_childrens == true ]]; then bisac_subject_1=JUV000000
elif [[ $subject_comedy == true ]]; then bisac_subject_1=HUM000000
elif [[ $subject_fantasy == true ]]; then bisac_subject_1=FIC009000
elif [[ $subject_scifi == true ]]; then bisac_subject_1=FIC028000
elif [[ $subject_adventure == true ]]; then bisac_subject_1=TRV001000
elif [[ $subject_mystery == true ]]; then bisac_subject_1=FIC022000
elif [[ $subject_horror == true ]]; then bisac_subject_1=FIC015000
elif [[ $subject_satire == true ]]; then bisac_subject_1=FIC052000
elif [[ $subject_travel == true ]]; then bisac_subject_1=TRV000000
elif [[ $subject_spirituality == true ]]; then bisac_subject_1=REL000000
elif [[ $subject_philosophy == true ]]; then bisac_subject_1=PHI000000
elif [[ $subject_fiction == true ]]; then bisac_subject_1=FIC000000
else bisac_subject_1=PHI021000
fi

## If multiple subjects, assign second using same hierarchy
if [[ $se_subject_count > 1 ]]; then
	if [[ $subject_drama == true && $bisac_subject_1 != "DRA000000" ]]; then bisac_subject_2=DRA000000
	elif [[ $subject_poetry == true && $bisac_subject_1 != "POE000000" ]]; then bisac_subject_2=POE000000
	elif [[ $subject_memoir == true && $bisac_subject_1 != "BIO026000" ]]; then bisac_subject_2=BIO026000
	elif [[ $subject_autobiography == true && $bisac_subject_1 != "BIO026000" ]]; then bisac_subject_2=BIO026000
	elif [[ $subject_biography == true && $bisac_subject_1 != "BIO000000" ]]; then bisac_subject_2=BIO000000
	elif [[ $subject_childrens == true && $bisac_subject_1 != "JUV000000" ]]; then bisac_subject_2=JUV000000
	elif [[ $subject_comedy == true && $bisac_subject_1 != "HUM000000" ]]; then bisac_subject_2=HUM000000
	elif [[ $subject_fantasy == true && $bisac_subject_1 != "FIC009000" ]]; then bisac_subject_2=FIC009000
	elif [[ $subject_scifi == true && $bisac_subject_1 != "FIC028000" ]]; then bisac_subject_2=FIC028000
	elif [[ $subject_adventure == true && $bisac_subject_1 != "TRV001000" ]]; then bisac_subject_2=TRV001000
	elif [[ $subject_mystery == true && $bisac_subject_1 != "FIC022000" ]]; then bisac_subject_2=FIC022000
	elif [[ $subject_horror == true && $bisac_subject_1 != "FIC015000" ]]; then bisac_subject_2=FIC015000
	elif [[ $subject_satire == true && $bisac_subject_1 != "FIC052000" ]]; then bisac_subject_2=FIC052000
	elif [[ $subject_travel == true && $bisac_subject_1 != "TRV000000" ]]; then bisac_subject_2=TRV000000
	elif [[ $subject_spirituality == true && $bisac_subject_1 != "REL000000" ]]; then bisac_subject_2=REL000000
	elif [[ $subject_philosophy == true && $bisac_subject_1 != "PHI000000" ]]; then bisac_subject_2=PHI000000
	elif [[ $subject_fiction == true && $bisac_subject_1 != "FIC000000" ]]; then bisac_subject_2=FIC000000
	else bisac_subject_2=PHI021000
	fi
fi

## Output subject codes
cat << EOF >> "${metadata_output}"
            <subjects>
                <subject primary="true" scheme="bisac">$bisac_subject_1</subject>
EOF
if [[ $se_subject_count > 1 ]]; then
	cat << EOF >> "${metadata_output}"
                <subject scheme="bisac">$bisac_subject_2</subject>
EOF
fi
cat << EOF >> "${metadata_output}"
            </subjects>
EOF

## Add description
long_description=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//opf:meta[@id='long-description']/text()" "${content_input}")
cat << EOF >> "${metadata_output}"
            <description format="html">$long_description</description>
EOF

## Add publication date
se_pub_date=$(xml sel  -N opf="http://www.idpf.org/2007/opf" -N dc="http://purl.org/dc/elements/1.1/" -t -c "//dc:date/text()" "${content_input}")
pub_date=${se_pub_date:0:10}
cat << EOF >> "${metadata_output}"
            <publisher>Standard Ebooks</publisher>
            <preorder_previews>true</preorder_previews>
EOF

## Add age range if children's fiction
if [[ $bisac_subject_1 == "JUV000000" || $bisac_subject_2 == "JUV000000" ]]; then
	cat << EOF >> "${metadata_output}"
            <audience_info>
                <audience scheme="interest-age-years">
                    <range>
                        <min_value>6</min_value>
                        <max_value>12</max_value>
                    </range>
                </audience>
            </audience_info>
EOF
fi

## Add publication date
cat << EOF >> "${metadata_output}"
            <publication_date>$pub_date</publication_date>
EOF

## Add pricing information with today's date

cat << EOF >> "${metadata_output}"
            <products>
                <product>
                    <territory>US</territory>
                    <cleared_for_sale>true</cleared_for_sale>
                    <price_tier>0</price_tier>
                    <release_type>other</release_type>
                    <sales_start_date>$(date +%Y-%m-%d)</sales_start_date>
                    <physical_list_price currency="USD">0.00</physical_list_price>
                    <drm_free>true</drm_free>
                </product>
            </products>
        </metadata>
EOF

## Add names of files, checksum variables, and footer
cat << EOF >> "${metadata_output}"
        <assets>
            <asset type="artwork">
                <data_file>
                    <file_name>cover.jpg</file_name>
                    <size>$cover_size</size>
                    <checksum type="md5">$cover_md5</checksum>
                </data_file>
            </asset>
            <asset type="full">
                <data_file>
                    <file_name>$epub_filename</file_name>
                    <size>$epub_size</size>
                    <checksum type="md5">$epub_md5</checksum>
                </data_file>
            </asset>
        </assets>
    </book>
</package>
EOF

# submit itmsp
if [[ $run_transporter == true ]]; then
	/usr/local/itms/bin/iTMSTransporter -m upload -f "${itmsp_name}" -u $transporter_username -p $transporter_password
else
	cp -r "${itmsp_name}" "${original_directory}/${se_name}.itmsp"
fi

# delete temp directory
rm -r "${path_to_repo}/temp"

# go back to original pwd
cd "${original_directory}"
