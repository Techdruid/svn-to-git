#!/bin/bash
#https://subversion.assembla.com/svn/notepad_project/
temp_dir=$(pwd)/temp
temp_dir2=temp_dir/$(basename $1)_temp
svn_dir=$temp_dir/$(basename $1)
git_dir=$temp_dir/$(basename $1).git

mkdir temp
cd $temp_dir
svn co $1
cd $svn_dir
svn log -q | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > authors-transform.txt
clear
echo 'Insert authors'' names in the following format'
echo 'username = Name Surname <email@me.info>'
read -n1 -r -p "Press space to continue..." key
if [ "$key" = ' ' ]; then
	nano authors-transform.txt
else
    nano authors-transform.txt
fi

cd $svn_dir
#convert svn to git
git svn clone $1 --no-metadata -A authors-transform.txt --stdlayout $temp_dir2

cd $temp_dir2
clear

#convert gitignore
git svn show-ignore > .gitignore
git add .gitignore
git commit -m 'Convert svn:ignore properties to .gitignore.'

#init new bare repository
git init --bare $git_dir
git symbolic-ref HEAD refs/heads/trunk
git remote add bare $git_dir

#add svn repo to bare repo
git config remote.bare.push 'refs/remotes/*:refs/heads/*'
git push bare

cd $git_dir
git branch -m trunk master
git for-each-ref --format='%(refname)' refs/heads/tags |
cut -d / -f 4 |
while read ref
do
  git tag "$ref" "refs/heads/tags/$ref";
  git branch -D "tags/$ref";
done

rm -rf $svn_dir
rm -rf $temp_dir2


