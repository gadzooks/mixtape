# Batch process playlists

## Testing : 

- Tested on Macbook running ruby 2.5.3.
- Would use Rspec for production code.

Test cases : 
1. apply empty json file for updates and verify that output.json matches mixtape-data.json
2. apply actual changes via data/changes.json and verify via diff.

## Usage : 
./process_playlist.rb

./process_playlist.rb data/changes.json

## Assumptions :
1. Since we are doing batch processing, we dont want to error out if we get bad
   data, ex creating a new playlist without any songs or with an invalid user
2. Assuming that the json schema for all the input files is valid. In
   production, I would use a JSON schema validator at the beginning and fail
   fast.
3. I am skipping entities which do not meet the business rules (ex: user with
   missing id or duplicate id). We would want to keep track of those and see
   why bad data is being generated.

## Possible scaling solutions :
> We may have to scale for Memory or CPU or both.

### Throw more hardware at it :
1. We are reading in the full json files in memory so we
   will likely run into memory issues before anything else. One fairly easy way
   to scale would be to add more memory. Its much cheaper to use a bigger
   server than to engineer a complicated solution (more complexity = more
   likelyhood of bugs). If nothing else this buys us time to figure out
   a longer term solution.
2. Add more CPU. Batch processing has SLAs, even though they are generally not
   as stringent as real time systems. As the file sizes grow it will take 
   longer and longer to process the files. At some point the rate at which new 
   files are being generated may become larger and we would never be able to
   catch up.

### Scaling for memory :
1. If we cant add more memory, I would look into breaking up the input files.
   One way to do this would be 3 separate files for users, songs and playlists.
   Users and songs would need to be processed before playlists can be. Each
   file can be loaded one at a time.
2. Even if we load each file separately we need to keep track of all the users,
   songs and playlists in memory which would limit how big the input files
   could be. This would require a different approach like using a NoSQL DB to
   keep track of the intermediate state or a local Berkely DB (an efficient
   key/value store), or a relational DB. This would offload keeping all the
   objects in memory while processing the files.
3. Since are are paring JSON we need to load the whole file before we can process
   it so loading partial files into memory would not work.
   If the files are so huge that they cannot fit in memory (even after
   splitting them up) then it may be time to look into other
   architecture patterns. Example : The process(es) creating these huge files
   could instead generate events which can be processed. Of course now you are
   going away from your batch processing setup so this would have to be
   carefully evaluated.

### Scaling for CPU :
1. Add benchmarking to see which part of the program is taking the most time
   and see if we can improve those code sections.
2. Look at other languages like JRuby (similar to ruby) or Go (easy to learn)
   or Java (tons of resources available). We should use the right
   tool for the right job. Introducing new languages into a team (especially if
   there isnt a lot of expertise for the new language can be risky) so care
   should be taken when doing this.
3. We may be able to use existing libraries written in C/C++/Java or roll our
   own and call it in ruby. This *could* help with memory usage too, but would
   be my last resource since it increases the code complexity quite a bit.

