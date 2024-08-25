# No Package Manager

This describes a method and related tooling for accomplishing the results one typically finds in a package manager, but without the need for a package manager.

The result of this method is a cross-language/environment "package" ecosystem. One that is naturally decentralized since it doesn't even have a package manager to centralize. This involves describing functions and their combination with cryptography, so the resulting systems are verifiable and trust is established by means of proof. Such an ecosystem can't be controlled, even by a central governing authority of such a standard, since any party that presents compatible proof can participate and any fork in such proofs would persist as long as it is agreeable between only two actors.

Along the way, we aquire verifiable fully reproducible builds, and a method by which anyone can add new forms of builds and packages without permission or coordination with any other party. The method described here can be implemented anywhere, it's not a subscription service or a product for you to download and depend on (thus depending upon **me**), it is freedom from precisely that process of dependence.

## The Management of No Packages

A lot of work goes in to a package manager, but the interface typically involves taking a bunch of smaller things (packages) and installing them into an environment where they are accessible by a larger thing (your program, compiler, interpreter, OS, etc).

Many package managers have been built for many languages, operating systems, and other environments. They all have their own way of doing things, some use secure hashing to "lock" packages, some don't, but they all take a bunch of smaller things and put them somewhere for you to assemble into a new thing that includes them.

The process by which a program includes these packages along with other code is called the "build." With no package manager between the code you write and the build, we need to describe how to build a program without a package manager. It would need to be able to accept well defined identifiers for libraries (like a package manager would) and include them in its final build efficiently.

There are also cases in which installed packages are used directly by an interpreter, obviating any build process. As an example, packages globally installed into Python and Node.js are accessible by name at any time in the interpreter. But it is also true that each one of those packages went throught a "package build" phase prior to being published. So we can now descriminate two divergent use cases: one in which the package manager is the distribution vehicle for the result, and one in which it is not. In both cases, a build phase like we describe can be used either in publishing the package or in building the final software, which ever is more suitable to the parties that implement it.

The environment a package is installed into has an inherent relationship with any program seeking to use such a package (if the package wasn't going to be accessible to "me" in a "place i can see" then I would not appear to have installed a package). So the building of packages, and the building of programs that rely on such packages, are more similar that different.

Without a package "manager" in the way, we can maybe see more easily that the local files we include in our program and the files that are "installed" by the package manager are similar if not identical in characteristics. Since they are similar, we can secure them together without differentiating between "package files" and "local files." All code included in your program is part of your program, forgetting this is the root of any failure to secure one's program from the code of others.

The main section of this text begins with a simple definition for such a build in shell script. It is meant only as an example we can continue to modify through the text in order to demonstrate the proofs. For a more use case driven example the section "Functions Only (Mikeal's Method)" appears at the end, which introduces small constraints that make the proofs more useful in practice and allow us to explore ways to replace many features of package managers that are more specific to each language or environment.

Once we have secured the files included in a program it's not much more effort to secure our final build. As such, the heart of this text is divided in to two sections:

1. Inclusion Proofs (Replaces Package Naming and Locking, Adds Reproducable Builds)
2. Transformation Proofs (Secure Verifiable Builds)

This results in a secure and generic definition for securing packages and other files which is compabitible across any network, registry, or storage layer. Since it is nothing but hashes, there's not even encoding details to bikeshed.

The examples here use `git show` for a "package registry," relying on the cryptographic hashes of files already checked into `git`. Since this is done in shell script, it's easy to imagine replacing or otherwise extending such an interface to include any CLI one writes that retreives data by hash. This means the cryptographic identities that *anyone can define without coordination or prior agreement* are globally unique identifiers that anyone can string into any kind of network or storage layer they choose.

Transformation Proofs can also be used to describe the process of existing package managers and build tools, illuminating the potential for these proofs to be used **in package managers**, even though this is called "**no**pm," cause I'm not dualistic like that.

# Simple Build Definition

Here we define a simple shell script that takes individual JavaScript files and concatenates them into a larger file.

```zsh
#!/bin/sh

# Define the input files
input_files=("one.js" "two.js" "three.js")

# Concatenate the input files and print to stdout
cat "${input_files[@]}"
```

If you just want to do a simple <script> include, this is actually a working build already.

A CommonJS build would look like this:

```zsh
#!/bin/sh

# Define the input files
input_files=("one.js" "two.js" "three.js")

# Read the content of each file into a variable
content_one=$(cat "one.js")
content_two=$(cat "two.js")
content_three=$(cat "three.js")

# Print the CommonJS module to stdout
cat <<EOF
module.exports = {
  one: \`
$content_one
  \`,
  two: \`
$content_two
  \`,
  three: \`
$content_three
  \`
};
EOF
```

If you want it to be an ESM module you add this:

```zsh
#!/bin/sh

# Define the input files
input_files=("one.js" "two.js" "three.js")

# Read the content of each file into a variable
content_one=$(cat "one.js")
content_two=$(cat "two.js")
content_three=$(cat "three.js")

# Print the ES Module to stdout
cat <<EOF
export const one = \`
$content_one
\`;

export const two = \`
$content_two
\`;

export const three = \`
$content_three
\`;
EOF
```

If you want to minify it, you can do this:

```zsh
./build.sh | uglifyjs -c -m
```

Now that we have a simple build definition, we can move on to securing the files we include in our program ("locking" in package manager terms).

After that, we'll secure the process by which we build, such that any build process, not just one as trivial as the one above, can be secured in the same way. With that, we'll have the means to describe cross-platform, cross-language, purely cryptographic "packaging" that can be accomplished **without** a package manager or **within** a package manager itself.

# Inclusion Proofs

In our prior example, the build was a file that read other files directly and concatenated them together. We're going to make a slight modification to that process:

1. We're going to return an *inclusion proof* for our input files from the build process.
2. We're going to add a flag that allows us to build from that *inclusion proof* (looking up and verifying hash identities from `git show`) rather than local files.

Our build reads a bunch of files and performs a transformation on them to produce a new file that includes what it needs from these parts. The fact that these are "files" is not relevant, all builds takes a bunch of smaller things and combine them into a new thing. Files are obvious/easy to hash, other things a build may rely on could be more abstract or difficult to hash but accomplishable in any system.

Using `git show` to retrieve file content by hash identity means building from proof will only work if the files are actually checked in to git. This is a simple way to demonstrate core concepts, and is trivially replaced with any CLI that retrieves files by hash. We'll be using git's hash identity algorithm to secure the files we include in our program, so our proofs will expect this algorithm. That doesn't mean we're incompatible with other algorithms, it's easy to produce alternate identities for the same content using different algorithms, and once you know they are equivalent (verifiably so!) you can use them interchangably as you hold a verifiable proof of their equivalency.

```zsh
#!/bin/sh

identify() {
  # Make a git hash from a string
  echo "$1" | git hash-object --stdin
}

read_hash() {
  # Read a file by hash (must be committed to local git repo)
  local hash="$1"
  local content
  content=$(git show "$hash")

  # Validate the content by re-computing the hash
  local computed_hash
  computed_hash=$(echo "$content" | git hash-object --stdin)

  if [ "$computed_hash" != "$hash" ]; then
    echo "Validation failed: content hash does not match original hash" >&2
    return 1
  fi

  echo "$content"
}

# Define the source files
source_files=("one.js" "two.js" "three.js")

# Initialize variables
build_from_proof=false
proof_hashes=()

# Parse command-line arguments
while getopts ":i" opt; do
  case $opt in
    i)
      build_from_proof=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Initialize content list
content=()

if [ "$build_from_proof" = true ]; then
  # Build from proof mode
  while IFS= read -r hash; do
    proof_hashes+=("$hash")
  done
  for hash in "${proof_hashes[@]}"; do
    content_item=$(read_hash "$hash")
    if [ $? -ne 0 ]; then
      exit 1
    fi
    content+=("$content_item")
  done
else
  # No arguments passed, use local files
  for file in "${source_files[@]}"; do
    if [ -f "$file" ]; then
      content+=("$(cat "$file")")
    else
      echo "File not found: $file" >&2
      exit 1
    fi
  done
fi

# Simple concatenation for a build example
concatenated_content=$(printf "%s\n" "${content[@]}")

# Print the concatenated content to stdout
echo "$concatenated_content" > program.js

# Print the hashes of the content
for c in "${content[@]}"; do
  echo "$(identify "$c")"
done
```

```
% ./build.sh
a8ad70ecbc4cb81726bb7a3f0d09e5164f95bbd5
e4360d0a350feb1256781db8e63cdcb4b116ce23
9bed00d83c3925112f15cf7eb418469298bf5036
```

Now our build process writes a program (`program.js`) and outputs an inclusion proof.

This build program also accepts such a proof and builds from sources committed to git from the hash identities found in the inclusion proof.

```
% ./build.sh | ./build.sh -i
a8ad70ecbc4cb81726bb7a3f0d09e5164f95bbd5
e4360d0a350feb1256781db8e63cdcb4b116ce23
9bed00d83c3925112f15cf7eb418469298bf5036
```

You can verify it works by simply pipeing the output of the build into a new build with the `-i` flag. The output should be identical to `./build.sh`.

```
diff <(./build.sh) <(./build.sh | ./build.sh -i)
```

This diff should always be empty, so if you want a command that will fail if the build is not reproducable, you can use this:

```
bash -c 'diff <(./build.sh) <(./build.sh | ./build.sh -i) > /dev/null || exit 1'
```

**This** is a *verifiably reproducable* build.

Now, let's make the build process itself just as verifiable.

# Transformation Proofs

In our very simple build, the entire content of the parts are included in the final program. This means that we could, if we wished, parse the parts from the final program in order to *derive* a proof.

When transformations result in programs that can have their proofs derived from the result, or even a combination of the result and other information (like source-maps), we already have a verifiable build so long as we have knowledge of the build process.

If we can:
* Derive the inclusion proof from the build result,
* We are already in posession of the build result, and its inclusion proof,
* Knowing the build process we can call it with this proof and verify it is the same result.

**This** is a verifiable build.

However, there are many transformations which result in programs you cannot derive inclusion proof from 😅

In these cases, we need another proof that describes build *transformation*. A "transformation proof" represents the transformation of an *input* to an *output* by way of a single *transformation*. You can describe multiple transformations by chaining these proofs together, or by treating a large multi-stage process as a single transformation.

The proof is thus described as three hash identities in order:

1. *input* identity
2. *transformation* identity
3. *output* identity

This is a simple way to describe a transformation, and it is easy to see how this can be extended to more complex transformations.

We will now extend our previous example, writing a new `verifiable-build.js` file that calls `build.sh` and returns the transformation proof. This will demonstrate how to create a transformation proof from a build process when such a proof cannot be derived from the build result. So we will describe our prior build process which implemented our inclusion proof as a transformation proof in the following way:

1. Our *input* identity will be the identity of the full inclusion proof from our build. This means it would be identical if we were to pipe the output of the build directly or write it to a file.
2. `build.sh` describes our entire *transformation*. Since it depends on no other files other than those described in the inclusion proof, we can use the hash of `build.sh` as the *transformation* identity. If the build depended on other state we'd need to find a way to include that in the identity as well. *This topic will be explored later.*
3. Our *output* identity will be the identity of the final program.

```zsh
#!/bin/sh

identify() {
  # Make a git hash from a string
  echo "$1" | git hash-object --stdin
}

# Run the build script and capture the inclusion proof
inclusion_proof=$(./build.sh)

# Compute the hash of the inclusion proof
input_identity=$(identify "$inclusion_proof")

# Compute the hash of the build script
transformation_identity=$(identify "$(cat build.sh)")

# Compute the hash of the final program
output_identity=$(identify "$(cat program.js)")

proof=(
  "$input_identity"
  "$transformation_identity"
  "$output_identity"
)

# Print the transformation proof
for c in "${proof[@]}"; do
  echo c
done
```

That's it.

The following command will trigger a build and return our proof.

```
./verifiable-build.sh
```

There's a lot more that package managers do than just install files and lock them. We're going to continue to explore those, but this will be done by describing and signing information **about** these proofs. Rather than design around a central schema, or a central authority, we're going to allow for any schema to be used, and any authority you trust to be trusted.

Hash identities are universal global identifiers. We can build many highly compatible systems and protocols if we separate what can and cannot be verified. Since what we've described so far is a universal system, we can build many different systems on top of it. Files, packages, builds, and more can all be shared with only what we've already described.

# Functions Only (Mikeal's Method)

From this point forward, we're going to describe a system that presumes the *inclusions* (js files in our example) are all describing single functions.

This is for simplicity of presentation and the honest preference of the author. What is being described can also be described with more complex structures like classes, modules, or even entire programs. However, the more complex the structure, the more complex the system that must be present to verify it.

By staying simple we get to demonstrate the cryptography and the trust model without getting bogged down in the details. We'll also be assuming that the names of the functions can be derived from the content of the inclusions themselves because we don't want to design another structure for that to live in 😁 In use cases where this is not true, the function name information from elsewhere must be included in the inclusion identity or else you'll suffer from unverifiability caused by this indeterminism.

Most package managers are built before, or addressing systems built before, the rise of modern AI. They are built for developers first, automation second, and AI is rarely considered a consumer. We're going to reverse this order, so that our primary audience is AI, then automation, and finally developers. As such, we're free to imagine a system in which individual and bots can publish without permission granting but where what is being published is not just untrusted but highly suspect. When package registries take on the curation and moderation role they are known for they also leave the packages that are not curated or moderated to be "blessed." If malware was every published, it would be removed once such information was known.

As there is no registry, there is no central means by which one can curate such a list. Malware will be published, and if you are not verifying it isn't malware, you are at risk. This is the world we are building for. It's actually the world we already live in, supply chain attacks have been happening for years, and the best defense we have is AI detection like [Socket.dev](https://socket.dev). A publishing system that presumes from the beginning that packages are not presumed to be anything other than malware without other knowledge is a good way to build a system that is robust and not easily attacked.

We'll continue to utilize `git` for our "registry" and we'll using GitHub Actions for our "computing environment." This involves utilizing some underappreciated features of git, like the ability to commit blobs directly without a filename. We'll model our workflow from code change, to build, publish, numerous forms of verification and improvement, re-publishing, and finally consumption all by adding information to git branches, pushing them, and utilizing the trigger of a push to run a script that does the next step.

In each of these steps, the workflow could easily be split between actors, and when these methods are implemented in open networks numerous actors will take on many of these steps in parallel. GitHub Actions are simply a means by which we can present the separation of actors with varied concerns responding to information. Much of what we discuss could also be applied to existing package managers and their publishing workflows should they implement proofs and signatures rather than, or even alongside, centralized authorities.

onchange:
  - in main branch: build and publish proofs to published branch
  - in published branch: verify proofs and publish a verification signature back to the published branch **for AI and automation to consume**
  - in verified branch: publish signed facts and views about the build to the info branch
  - in info branch: verify facts and publish a markdown file back to the info branch **for humans to read**

In the end, we end up with a system that proactively validates a lot about packages before humans are ever even notified of a package existing. Software developers and AI that consume these functions have numerous facts and views about a package they can see and authenticate themselves if they don't trust the signers.

Since nothing is being described or exchanged other than hash identities, proofs, signatures, and information that arrives at these through computation, we can build a system that is highly compatible with many different systems and protocols. We can also build a system that is highly resistant to attack and highly resilient to failure. We haven't even defined what programming language this is for, and we don't need to because we'll only ever concern ourselves with data that has gone through verification that it is the language we prefer when we consume it. The same goes for any other characteristic.

🚧🚧🚧🚧🚧🚧🚧🚧

Under Construction

🚧🚧🚧🚧🚧🚧🚧🚧
