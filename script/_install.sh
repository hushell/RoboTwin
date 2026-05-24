echo "Installing the necessary packages ..."
/data/hushell/lingbot-va/lingbot-va/.venv/bin/pip install -r script/requirements.txt

echo "Installing pytorch3d ..."
# cd third_party/pytorch3d_simplified
# /data/hushell/lingbot-va/lingbot-va/.venv/bin/pip install -e .
# cd ../..
/data/hushell/lingbot-va/lingbot-va/.venv/bin/pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable" --no-build-isolation --no-build-isolation

echo "Adjusting code in sapien/wrapper/urdf_loader.py ..."
# location of sapien, like "~/.conda/envs/RoboTwin/lib/python3.10/site-packages/sapien"
SAPIEN_LOCATION=$(/data/hushell/lingbot-va/lingbot-va/.venv/bin/pip show sapien | grep 'Location' | awk '{print $2}')/sapien
# Adjust some code in wrapper/urdf_loader.py
URDF_LOADER=$SAPIEN_LOCATION/wrapper/urdf_loader.py
# ----------- before -----------
# 667         with open(urdf_file, "r") as f:
# 668             urdf_string = f.read()
# 669 
# 670         if srdf_file is None:
# 671             srdf_file = urdf_file[:-4] + "srdf"
# 672         if os.path.isfile(srdf_file):
# 673             with open(srdf_file, "r") as f:
# 674                 self.ignore_pairs = self.parse_srdf(f.read())
# ----------- after  -----------
# 667         with open(urdf_file, "r", encoding="utf-8") as f:
# 668             urdf_string = f.read()
# 669 
# 670         if srdf_file is None:
# 671             srdf_file = urdf_file[:-4] + ".srdf"
# 672         if os.path.isfile(srdf_file):
# 673             with open(srdf_file, "r", encoding="utf-8") as f:
# 674                 self.ignore_pairs = self.parse_srdf(f.read())
sed -i -E 's/("r")(\))( as)/\1, encoding="utf-8") as/g' $URDF_LOADER


echo "Adjusting code in mplib/planner.py ..."
# location of mplib, like "~/.conda/envs/RoboTwin/lib/python3.10/site-packages/mplib"
MPLIB_LOCATION=$(/data/hushell/lingbot-va/lingbot-va/.venv/bin/pip show mplib | grep 'Location' | awk '{print $2}')/mplib

# Adjust some code in planner.py
# ----------- before -----------
# 807             if np.linalg.norm(delta_twist) < 1e-4 or collide or not within_joint_limit:
# 808                 return {"status": "screw plan failed"}
# ----------- after  ----------- 
# 807             if np.linalg.norm(delta_twist) < 1e-4 or not within_joint_limit:
# 808                 return {"status": "screw plan failed"}
PLANNER=$MPLIB_LOCATION/planner.py
sed -i -E 's/(if np.linalg.norm\(delta_twist\) < 1e-4 )(or collide )(or not within_joint_limit:)/\1\3/g' $PLANNER

echo "Installing Curobo ..."
cd envs
# RoboTwin requires curobo 0.7.x API (curobo.types.math, curobo.wrap.reacher.motion_gen).
CUROBO_COMMIT=cca894de9ec74e77a0a4071319c81958991a9108
if [ ! -d curobo/.git ]; then
    git clone https://github.com/NVlabs/curobo.git
fi
cd curobo
git fetch origin "${CUROBO_COMMIT}"
git checkout "${CUROBO_COMMIT}"
# Remove stale top-level curobo/ package dir from newer curobo versions (v0.8+).
rm -rf curobo
/data/hushell/lingbot-va/lingbot-va/.venv/bin/pip install -e . --no-build-isolation
cd ../..

echo "Installation basic environment complete!"
echo -e "You need to:"
echo -e "    1. \033[34m\033[1m(Important!)\033[0m Download assets from huggingface."
echo -e "    2. Install requirements for running baselines. (Optional)"
echo "See INSTALLATION.md for more instructions."
