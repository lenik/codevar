project('codevar', 'c',
  version : '1.0.0',
  license : 'GPL-3.0-or-later',
  default_options : ['warning_level=3'])

cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required : false)

# Build base91 executable
base91_src = files('base91.c')

base91_exe = executable('base91',
  base91_src,
  dependencies : [math_dep],
  install : true)

# Install codevar shell script
install_data('codevar',
  install_dir : get_option('bindir'),
  install_mode : 'rwxr-xr-x')

# Install man pages
install_man('base91.1')
install_man('codevar.1')

# Install bash completion
install_data('base91.bash-completion',
  install_dir : get_option('datadir') / 'bash-completion' / 'completions',
  rename : 'base91')
install_data('codevar.bash-completion',
  install_dir : get_option('datadir') / 'bash-completion' / 'completions',
  rename : 'codevar')

# Note: Symlinks are installed via install-symlinks target in Makefile
# which hardcodes /usr/bin paths

