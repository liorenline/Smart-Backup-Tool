import yaml
from pathlib import Path


def load_config(path):
    with open(path, encoding="utf-8") as stream:
        config = yaml.safe_load(stream)

    for key in ["paths", "s3"]:
        if key not in config:
            raise ValueError(f"Config is missing required field: {key}")

    for key in ["bucket", "prefix", "profile"]:
        if key not in config["s3"]:
            raise ValueError(f"Config is missing required field: s3.{key}")

    return config

if __name__ == "__main__":
    project_root = Path(__file__).resolve().parent.parent
    print(load_config(project_root / "backup_config.yaml"))