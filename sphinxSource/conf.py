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
html_last_updated_fmt = "%a, %d %b %Y %H:%M:%S"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ['sphinx.ext.githubpages']

templates_path = ['_templates']
exclude_patterns = []



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
extensions.append("sphinx_wagtail_theme")
html_theme = 'sphinx_wagtail_theme'
html_theme_options = dict(
    project_name = "IVOA Documentation View",
    html_title = "IVOA Docs",
    logo = "img/ivoa_logo71x40.jpg",
    logo_alt = "IVOA",
    logo_height = 40,
    logo_width = 71,
    logo_url = "/",
    html_favicon = "https://raw.githubusercontent.com/ivoa/ivoa-web/refs/heads/main/static/favicon/favicon.ico",
    github_url = "https://github.com/ivoa/IvoaDocViewSite/blob/main/sphinxSource/",
    footer_links= "IVOA Home|https://www.ivoa.net, Official Document Repository|https://www.ivoa.net/documents/, XML Schema|https://www.ivoa.net/xml/, Vocabularies|https://www.ivoa.net/rdf/"
)
html_static_path = ['_static']

html_css_files = ["ivoa.css"]
