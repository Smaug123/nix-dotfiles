open System.IO
open System.Net.Http
open System.Text.Json

type Extension =
    {
        Name : string
        Publisher : string
        Version : string
        Sha256 : string
    }
    override this.ToString () =
        [
            "{"
            $"    name = \"{this.Name}\";"
            $"    publisher = \"{this.Publisher}\";"
            $"    version = \"{this.Version}\";"
            $"    sha256 = \"{this.Sha256}\";"
            "}"
        ]
        |> String.concat "\n"

    static member Parse (s : string list) : Extension =
        let collection =
            s
            |> List.fold (fun fields s ->
                match s.Split "=" |> List.ofArray with
                | field :: rest when not <| rest.IsEmpty ->
                    Map.add (field.Trim ()) ((String.concat "=" rest).Split('"').[1].TrimEnd(';')) fields
                | _ -> fields
            ) Map.empty

        {
            Name = collection.["name"]
            Publisher = collection.["publisher"]
            Version = collection.["version"]
            Sha256 = collection.["sha256"]
        }

type Skipped =
    {
        NixpkgsRef : string
        Reason : string
    }
    override this.ToString () =
        [
            $"# {this.Reason}"
            $"#    {this.NixpkgsRef}"
        ]
        |> String.concat "\n"

let bimap f g (x, y) = (f x, g y)

let partition<'a, 'b> (l : List<Choice<'a, 'b>>) : 'a list * 'b list =
    l
    |> List.fold (fun (aEntries, bEntries) next ->
        match next with
        | Choice1Of2 a -> (a :: aEntries, bEntries)
        | Choice2Of2 b -> (aEntries, b :: bEntries)
    ) ([], [])
    |> bimap List.rev List.rev

type NixFile =
    {
        NixpkgsRefs : string list
        Skipped : Skipped list
        SpecificVersions : Extension list
    }
    override this.ToString () =
        [
            yield "{ pkgs }:"
            yield ""
            yield "with pkgs.vscode-extensions; ["
            yield! this.NixpkgsRefs |> List.map (sprintf "    %s")
            yield! this.Skipped |> List.map (sprintf "%O")
            yield "] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace ["
            yield! this.SpecificVersions |> List.map (sprintf "%O")
            yield "]"
        ]
        |> String.concat "\n"

    static member Parse (s : string) : NixFile =
        let pre, post =
            s.Split "++ pkgs.vscode-utils.extensionsFromVscodeMarketplace ["
            |> function
                | [| pre ; post |] -> pre, post
                | _ -> failwith "Unexpected number of '++'"

        let verbatim, skipped =
            match pre.Split "\n" |> List.ofArray with
            | "{pkgs}:" :: "with pkgs.vscode-extensions;" :: "  [" :: rest ->
                rest
                |> List.map (fun s ->
                    if s.StartsWith '#' then Choice2Of2 (s.[2..].Trim()) else Choice1Of2 (s.Trim())
                )
                |> partition
            | _ -> failwith $"Unexpected pre:\n{pre}"
        let pairs (l : 'a list) : ('a * 'a) list =
            let rec go acc l =
                match l with
                | [] -> acc
                | [singleton] -> failwith $"Expected pair, got {singleton}"
                | x :: y :: rest -> go ((x, y) :: acc) rest
            go [] l
            |> List.rev
        let skipped =
            skipped
            |> pairs
            |> List.map (fun (comment, link) -> { NixpkgsRef = link ; Reason = comment })

        let specificVersions =
            post.TrimEnd([| '\n' ; ']'|]).Split "}"
            |> Array.choose (fun contents ->
                match contents.Trim([|'\n' ; ' '|]).Split "\n" |> List.ofArray with
                | "{" :: rest ->
                    Some (Extension.Parse rest)
                | [] ->
                    failwith $"Expected extension, got:\n{contents}"
                | [""] -> None
                | fst :: rest ->
                    failwith $"Expected bracket, got '{fst}'\n {rest}"
            )
            |> Array.toList

        {
            Skipped = skipped
            NixpkgsRefs = verbatim
            SpecificVersions = specificVersions
        }

type Version =
    {
        Version : string
        TargetPlatform : string
    }

let upgradeExtension (client : HttpClient) (e : Extension) : Extension Async =
    let uri = System.Uri $"https://marketplace.visualstudio.com/items?itemName={e.Publisher}.{e.Name}"
    async {
        let! response = client.GetAsync uri |> Async.AwaitTask
        let! content = response.Content.ReadAsStringAsync () |> Async.AwaitTask
        let options = JsonSerializerOptions ()
        options.PropertyNameCaseInsensitive <- true
        let latestVersion =
            content.Split("\"Versions\":[").[1].Split("]").[0]
            |> sprintf "[%s]"
            |> fun s -> JsonSerializer.Deserialize<Version array> (s, options)
            |> Seq.head
        return { e with Version = latestVersion.Version }
    }

let upgrade (nixFile : NixFile) : NixFile =
    use client = new HttpClient ()
    { nixFile with
        SpecificVersions =
            nixFile.SpecificVersions
            |> List.map (upgradeExtension client)
            |> Async.Parallel
            |> Async.RunSynchronously
            |> List.ofArray
    }

module Program =

    [<EntryPoint>]
    let main args =
        let sourceFile =
            if args.Length = 0 then "vscode-extensions.nix" else args.[0]

        File.ReadAllText sourceFile
        |> NixFile.Parse
        |> upgrade
        |> sprintf "%O"
        |> fun s -> File.WriteAllText (sourceFile, s)

        0