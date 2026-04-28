# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information
import sys
from pathlib import Path

#for local extensions
sys.path.append(str(Path('_ext').resolve()))
project = 'IVOA Documentation View'
author = 'Paul Harrison'
html_show_copyright = False
release = '0.1'
html_title = "IVOA DocView"
html_favicon = "https://raw.githubusercontent.com/ivoa/ivoa-web/refs/heads/main/static/favicon/favicon.ico"
html_last_updated_fmt = "%a, %d %b %Y %H:%M:%S"
numfig = True

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ['sphinx.ext.githubpages']

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
extensions.append("pydata_sphinx_theme")
html_theme = 'pydata_sphinx_theme'
html_theme_options = {
    "logo": {
        "image_light": "_static/img/ivoa_logo71x40.jpg",
        "image_dark": "_static/img/ivoa_logo71x40.jpg",
        "text": "IVOA DocView",
        "alt_text": "IVOA",
    },
    "navbar_start": ["navbar-logo"],
    "navbar_center": ["navbar-nav"],
    "navbar_end": ["theme-switcher", "navbar-icon-links"],
    "navbar_persistent": ["search-button"],
    "icon_links": [
        {
            "name": "GitHub",
            "url": "https://github.com/ivoa/IvoaDocViewSite",
            "icon": "fa-brands fa-github",
        }
    ],
}
html_static_path = ['_static']

html_css_files = ["ivoa.css"]

# bibliography https://sphinxcontrib-bibtex.readthedocs.io/en/latest/index.html
extensions.append("sphinxcontrib.bibtex")
bibtex_bibfiles = ["../src/ivoatex/docrepo.bib"] # TODO add the individual bib files (though need to worry about duplicates and labels below....)
bibtex_default_style = 'IvoaStyle'

import pybtex.plugin
from pybtex.style.formatting.alpha import Style as AlphaStyle
from pybtex.style.labels.alpha import LabelStyle as AlphaLabelStyle
from pybtex.style.sorting import BaseSortingStyle

class IvoaLabelStyle(AlphaLabelStyle):
    """
    make the label look like document shortname and version
    """
    def format_label(self, entry): # TODO is this right for bib entries that do not have these fields
        doc = entry.fields.get("ivoa_docname", entry.key)
        ver = entry.fields.get("version", "")
        return f"{doc}{ver}"

class IvoaSorting(BaseSortingStyle):
    def sorting_key(self, entry):
        doc = entry.fields.get("ivoa_docname", entry.key)
        ver = entry.fields.get("version", "")
        return (doc, ver)


class IvoaStyle(AlphaStyle):
    default_label_style = IvoaLabelStyle
    default_sorting_style = IvoaSorting

pybtex.plugin.register_plugin('pybtex.style.formatting', 'IvoaStyle', IvoaStyle)
