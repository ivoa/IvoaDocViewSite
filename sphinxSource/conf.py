# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'IVOA Documentation View'
copyright = '2025, Paul Harrison'
author = 'Paul Harrison'
release = '0.1'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = []

templates_path = ['_templates']
exclude_patterns = []



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
extensions.append("sphinx_wagtail_theme")
html_theme = 'sphinx_wagtail_theme'
html_theme_options = dict(
    project_name = "IVOA Documentation",
    logo = "img/ivoa_logo71x40.jpg",
    logo_alt = "IVOA",
    logo_height = 40,
    logo_width = 71,
    logo_url = "/"
)
html_static_path = ['_static']

html_css_files = ["ivoa.css"]
