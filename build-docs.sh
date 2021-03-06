#!/usr/bin/env bash

# Description: Build script for Project Dovetail documentation
# Author: retgits <https://github.com/retgits>
# Mod: fcenedes@tibco.com
# Last Updated: 2018-11-11

#--- Variables ---
HUGO_VERSION=0.50
GIT_ACCOUNT="TIBCOSoftware"
GIT_REPO="dovetail"

#--- Download and install prerequisites ---
prerequisites() {
    wget -O hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
    mkdir -p hugobin
    tar -xzvf hugo.tar.gz -C ./hugobin
    mv ./hugobin/hugo $HOME/gopath/bin
    rm hugo.tar.gz && rm -rf ./hugobin
}

#--- Get external docs ---
ext_docs() {
    echo "cloning dovetail-contrib"
    git clone https://github.com/TIBCOSoftware/dovetail-contrib.git 
    #for i in `find dovetail-contrib/activity -name \*.md` ; do filename=$(basename $(dirname $i)); cp $i docs/content/development/webui/activities/$filename.md; done;
    #for i in `find dovetail-contrib/trigger -name \*.md` ; do filename=$(basename $(dirname $i)); cp $i docs/content/development/webui/triggers/$filename.md; done;
    rm -rf ./dovetail-contrib
}

#--- Add readme and license ---
add_readme() {
    echo "Adding readme and license files"
    cp docs/content/README.md docs/public
    cp docs/content/LICENSE docs/public
}

update_page_cli() {
    echo "Getting the docs for the commandline tools"
    #curl -o docs/content/dovetail-cli/dovetail-cli.md https://raw.githubusercontent.com/TIBCOSoftware/dovetail-cli/master/docs/dovetail-cli.md
}

#--- Update contributions page ---
update_page_contrib() {
    echo "Update contributing page"
    cp CONTRIBUTING.md docs/content/contributing/contributing.md
    sed -i '1d' docs/content/contributing/contributing.md
    sed -i '1i ---' docs/content/contributing/contributing.md
    sed -i '1i weight: 9010' docs/content/contributing/contributing.md
    sed -i '1i title: Contributing to Project Dovetail' docs/content/contributing/contributing.md
    sed -i '1i ---' docs/content/contributing/contributing.md
}

#--- Update introduction page ---
update_page_introduction() {
    cp README.md docs/content/introduction/_index.md
    sed -i '1,4d' docs/content/introduction/_index.md
    sed -i '5,17d' docs/content/introduction/_index.md
    sed -i '1i ---' docs/content/introduction/_index.md
    sed -i '1i pre: "<i class=\\"fas fa-home\\" aria-hidden=\\"true\\"></i> "' docs/content/introduction/_index.md
    sed -i '1i weight: 1000' docs/content/introduction/_index.md
    sed -i '1i title: Introduction' docs/content/introduction/_index.md
    sed -i '1i ---' docs/content/introduction/_index.md
    sed -i "s#images/eventhandlers.png#../images/eventhandlers.png#g" docs/content/introduction/_index.md
}

#--- Update page ---
update_page() {
    case "$1" in
        "contributing")
            update_page_contrib
            ;;
        "introduction")
            update_page_introduction
            ;;
        *)
            echo "Updating all pages"
            ext_docs
            update_page_cli
            update_page_contrib
            update_page_introduction
    esac
}

#--- Execute build ---
build() {
    echo "Build docs site..."
    cd docs && hugo
    #cd ../showcases && hugo
    #mv public ../docs/public/showcases
    cd public/
    ls -alh
    cd ../../
}

gitprep() {
    if [ -d "dovetail" ]; then
        echo "Your working directory is dirty, please run the script again after cleaning it up"
        exit 1;
    fi 
    echo "cloning dovetail"
    git clone https://github.com/TIBCOSoftware/dovetail.git
    cd dovetail
    echo "Deleting old publication"
    cd docs
    rm -rf public
    mkdir public
    git worktree prune
    rm -rf .git/worktrees/public/
    echo "Checking out gh-pages branch into public"
    git worktree add -B gh-pages public origin/gh-pages
    echo "Removing existing files"
    rm -rf public/*
    cd ../
    echo $PWD  
}

gitupdate() {
    echo "Updating gh-pages branch"
    cd docs
    git add -A .
    cd public
    git add -A .
    git commit -a -m "Publishing to gh-pages (build-doc.sh)" 
    if [[ $(git status -s) ]]
        then
        echo "The working directory is dirty. Please commit any pending changes."
        exit 1;
    fi 
    git push origin gh-pages
}


case "$1" in 
    "prerequisites")
        prerequisites
        ;;
    "ext-docs")
        ext_docs
        ;;
    "update-page")
        update_page $2
        ;;
    "build")
        build
        ;;
    "magic")
        gitprep
        update_page $2
        add_readme
        build
        gitupdate
        ;;
        
    *)
        echo "The target {$1} you want to execute doesn't exist"
esac
