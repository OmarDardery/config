"""Initialize missing app palettes without choosing or changing the wallpaper."""
import os
from pathlib import Path
import subprocess
import sys
import tomllib


def seed(binary, config_path, state_path, pictures, samples):
    with open(config_path, 'rb') as stream:
        config = tomllib.load(stream)
    state = {}
    if Path(state_path).is_file():
        with open(state_path, 'rb') as stream:
            state = tomllib.load(stream)
    templates = config['theme']['templates']['user']
    missing = [t for t in templates.values()
               if not Path(t['output_path']).exists() and not Path(t['output_path']).is_symlink()]
    if not missing:
        return
    selected = state.get('wallpaper', {}).get('default', {}).get('path', '')
    image = Path(os.path.expanduser(selected)) if selected else None
    if image is None or not image.is_file():
        # A bootstrap palette only; this never saves a selected wallpaper.
        image = next((p for directory in (pictures, samples)
                      for p in sorted(Path(directory).glob('*'))
                      if p.is_file() and p.suffix.lower() in {'.jpg', '.jpeg', '.png', '.webp', '.avif'}), None)
    if image is None:
        raise RuntimeError('No image is available for initial app palettes')
    theme = state.get('theme', {})
    command = [binary, 'theme', str(image), '-o', os.devnull]
    if theme.get('wallpaper_scheme'):
        command += ['--scheme', theme['wallpaper_scheme']]
    if theme.get('mode') == 'light':
        command += ['--default-mode', 'light']
    if theme.get('pure_black_dark'):
        command += ['--pure-black']
    for template in missing:
        Path(template['output_path']).parent.mkdir(parents=True, exist_ok=True)
        command += ['--render', template['input_path'] + ':' + template['output_path']]
    subprocess.run(command, check=True)


if __name__ == '__main__':
    seed(*sys.argv[1:])
