from pathlib import Path
BASE=Path(__file__).resolve().parent
code=(BASE/'validate_walk_v4.py').read_text(encoding='utf-8')
changes=[("'v3','v4'","'v5','v6'"),("version=='v3'","version=='v5'"),("/MIKO7/v4","/MIKO7/v6"),("MIKO7_Walk","MIKO7_Sprint"),("range(31))+[0,2,1,30,0]","range(19))+[0,2,1,18,0]"),("snapshots[(30,p.name)]","snapshots[(18,p.name)]"),("walk_","sprint_"),("WALK_V4_CHECK","SPRINT_V6_BAKE_CHECK")]
for old,new in changes:
    assert old in code,old
    code=code.replace(old,new)
exec(compile(code,str(BASE/'generated_sprint_validation.py'),'exec'))
