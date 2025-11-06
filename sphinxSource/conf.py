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
html_title = "IVOA Docs"
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
# https://sphinx-wagtail-theme.readthedocs.io/en/latest/index.html
extensions.append("sphinx_wagtail_theme")
#html_theme = 'sphinx_wagtail_theme'
html_theme_options = dict(
    project_name = "IVOA Documentation View",
    logo = "img/ivoa_logo71x40.jpg",
    logo_alt = "IVOA",
    logo_height = 40,
    logo_width = 71,
    logo_url = "/",
    github_url = "https://github.com/ivoa/IvoaDocViewSite/blob/main/sphinxSource/",
    footer_links= "IVOA Home|https://www.ivoa.net, Official Document Repository|https://www.ivoa.net/documents/, XML Schema|https://www.ivoa.net/xml/, Vocabularies|https://www.ivoa.net/rdf/"
)
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
    def format_label(self, entry): # FIXME need to worry about bib entries that do not have these fields
        return entry.fields["ivoa_docname"] + entry.fields["version"]

class IvoaSorting(BaseSortingStyle):
    def sorting_key(self, entry):
        return (entry.fields["ivoa_docname"] , entry.fields["version"])


class IvoaStyle(AlphaStyle):
    default_label_style = IvoaLabelStyle
    default_sorting_style = IvoaSorting

pybtex.plugin.register_plugin('pybtex.style.formatting', 'IvoaStyle', IvoaStyle)
