defmodule GitRepoTest do
  use ExUnit.Case
  alias Paradigm.Graph
  alias Paradigm.Graph.GitRepoGraph

  describe "git repo graph adapter" do
    setup do
      # Create a temporary directory for the git repo
      temp_dir = System.tmp_dir!() |> Path.join("git_repo_test_#{:rand.uniform(1000000)}")
      File.mkdir_p!(temp_dir)

      # Initialize git repo
      System.cmd("git", ["init"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["config", "user.name", "Test User"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["config", "user.email", "test@example.com"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Create initial file and commit
      initial_file = Path.join(temp_dir, "README.md")
      File.write!(initial_file, "# Test Repository\n\nInitial content")
      System.cmd("git", ["add", "README.md"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Initial commit"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Create and modify some files
      file1 = Path.join(temp_dir, "file1.txt")
      File.write!(file1, "Content of file 1")
      System.cmd("git", ["add", "file1.txt"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Add file1.txt"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Modify existing file
      File.write!(initial_file, "# Test Repository\n\nUpdated content\n\nMore changes")
      System.cmd("git", ["add", "README.md"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Update README"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Create a new branch
      System.cmd("git", ["checkout", "-b", "feature-branch"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Add file on feature branch
      file2 = Path.join(temp_dir, "feature.txt")
      File.write!(file2, "Feature file content")
      System.cmd("git", ["add", "feature.txt"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Add feature file"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Modify file1 on feature branch
      File.write!(file1, "Content of file 1\nFeature branch changes")
      System.cmd("git", ["add", "file1.txt"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Modify file1 on feature branch"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Switch back to main and make another commit
      System.cmd("git", ["checkout", "main"], cd: temp_dir, stderr_to_stdout: true, into: "")
      file3 = Path.join(temp_dir, "main-only.txt")
      File.write!(file3, "File only on main branch")
      System.cmd("git", ["add", "main-only.txt"], cd: temp_dir, stderr_to_stdout: true, into: "")
      System.cmd("git", ["commit", "-m", "Add main-only file"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # Merge feature branch
      System.cmd("git", ["merge", "feature-branch"], cd: temp_dir, stderr_to_stdout: true, into: "")

      # on_exit(fn ->
      #   File.rm_rf(temp_dir)
      # end)

      {:ok, repo_path: temp_dir}
    end

    test "lists git revisions", %{repo_path: repo_path} do
      {output, 0} = System.cmd("git", ["log", "--oneline", "--all"], cd: repo_path)

      lines = String.split(output, "\n", trim: true)
      assert length(lines) >= 6

      # Check that we have some expected commit messages
      commit_messages = Enum.join(lines, " ")
      assert commit_messages =~ "Initial commit"
      assert commit_messages =~ "Add file1.txt"
      assert commit_messages =~ "Update README"
      assert commit_messages =~ "Add feature file"
      assert commit_messages =~ "Add main-only file"
    end

    test "checks out a specific revision and reads files", %{repo_path: repo_path} do
      # Get the commit hash for the "Add file1.txt" commit
      {output, 0} = System.cmd("git", ["log", "--oneline", "--grep=Add file1.txt"], cd: repo_path)
      [commit_line | _] = String.split(output, "\n", trim: true)
      [commit_hash | _] = String.split(commit_line, " ")

      # Checkout that specific commit
      {_, 0} = System.cmd("git", ["checkout", commit_hash], cd: repo_path, stderr_to_stdout: true, into: "")

      # Read files at that point in history
      readme_content = File.read!(Path.join(repo_path, "README.md"))
      assert readme_content == "# Test Repository\n\nInitial content"

      file1_content = File.read!(Path.join(repo_path, "file1.txt"))
      assert file1_content == "Content of file 1"

      # Files that don't exist yet at this revision should not be present
      refute File.exists?(Path.join(repo_path, "feature.txt"))
      refute File.exists?(Path.join(repo_path, "main-only.txt"))
    end

    test "checks out initial commit and verifies file state", %{repo_path: repo_path} do
      # Get the commit hash for the initial commit
      {output, 0} = System.cmd("git", ["log", "--oneline", "--grep=Initial commit"], cd: repo_path)
      [commit_line | _] = String.split(output, "\n", trim: true)
      [commit_hash | _] = String.split(commit_line, " ")

      # Checkout the initial commit
      {_, 0} = System.cmd("git", ["checkout", commit_hash], cd: repo_path, stderr_to_stdout: true, into: "")

      # At the initial commit, only README.md should exist
      readme_content = File.read!(Path.join(repo_path, "README.md"))
      assert readme_content == "# Test Repository\n\nInitial content"

      # No other files should exist yet
      refute File.exists?(Path.join(repo_path, "file1.txt"))
      refute File.exists?(Path.join(repo_path, "feature.txt"))
      refute File.exists?(Path.join(repo_path, "main-only.txt"))
    end

    test "checks out updated README commit and verifies content", %{repo_path: repo_path} do
      # Get the commit hash for the "Update README" commit
      {output, 0} = System.cmd("git", ["log", "--oneline", "--grep=Update README"], cd: repo_path)
      [commit_line | _] = String.split(output, "\n", trim: true)
      [commit_hash | _] = String.split(commit_line, " ")

      # Checkout that commit
      {_, 0} = System.cmd("git", ["checkout", commit_hash], cd: repo_path, stderr_to_stdout: true, into: "")

      # Verify README has updated content
      readme_content = File.read!(Path.join(repo_path, "README.md"))
      assert readme_content == "# Test Repository\n\nUpdated content\n\nMore changes"

      # file1.txt should exist with original content
      file1_content = File.read!(Path.join(repo_path, "file1.txt"))
      assert file1_content == "Content of file 1"

      # Feature files shouldn't exist yet
      refute File.exists?(Path.join(repo_path, "feature.txt"))
      refute File.exists?(Path.join(repo_path, "main-only.txt"))
    end

    test "production of git repo graph", %{repo_path: repo_path} do
      graph = GitRepoGraph.new(root: repo_path)
      Paradigm.Conformance.assert_conforms(graph, Paradigm.Builtin.GitRepo.definition())

      Graph.get_all_nodes_of_class(graph, "commit")

      # Enum.each(nodes, fn node_id ->
      #   node = Graph.get_node(graph, node_id)
      #   IO.inspect(node)
      # end)
    end
  end
end
