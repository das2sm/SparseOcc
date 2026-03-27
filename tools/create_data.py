import argparse
import os
from tools.data_converter import nuscenes_converter as nuscenes

def nuscenes_data_prep(root_path, info_prefix, version, dataset_name, out_dir, max_sweeps=10):
    nuscenes.create_nuscenes_infos(root_path, out_dir, info_prefix, version=version, max_sweeps=max_sweeps)

parser = argparse.ArgumentParser(description='Data converter arg parser')
parser.add_argument('dataset', metavar='nuscenes', help='name of the dataset')
parser.add_argument('--root-path', type=str, default='./data/nuscenes', help='specify the root path of dataset')
parser.add_argument('--out-dir', type=str, default='./data/nuscenes', help='name of info pkl')
parser.add_argument('--extra-tag', type=str, default='nuscenes')
parser.add_argument('--version', type=str, default='v1.0-trainval')

if __name__ == '__main__':
    args = parser.parse_args()
    if args.dataset == 'nuscenes':
        nuscenes_data_prep(
            root_path=args.root_path,
            info_prefix=args.extra_tag,
            version=args.version,
            dataset_name='NuScenesDataset',
            out_dir=args.out_dir,
            max_sweeps=10)
