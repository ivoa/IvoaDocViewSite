"""
script to create a map from docname to bibcode of the latest versions
"""
import subprocess
import bibtexparser


def main():
    library =bibtexparser.parse_file("src/ivoatex/docrepo.bib")
    docs = subprocess.check_output("awk -F= '/^DOCNAME/{gsub(/[ \\t]/,\"\",$2);print $2}' src/*/Makefile", shell=True,  text=True).split()

    with open("pandocCustomization/latest_versions_map.yaml", "w") as f:
        for bibcode, entry in library.entries_dict.items():
            fields = entry.fields_dict
            if "ids" in fields.keys():
                if fields["ivoa_docname"].value in docs:
                    f.write(f"{fields["ivoa_docname"].value}: \"{bibcode}\"\n")

if __name__=="__main__":
    main()