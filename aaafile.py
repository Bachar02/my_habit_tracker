import os

def copy_multiple_files(file_paths):
    results = {}
    
    for file_path in file_paths:
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            results[file_path] = {
                'success': True,
                'content': content,
                'size': len(content)
            }
        except FileNotFoundError:
            results[file_path] = {
                'success': False,
                'error': f"File not found: {file_path}"
            }
        except Exception as e:
            results[file_path] = {
                'success': False,
                'error': f"Error reading file: {str(e)}"
            }
    
    return results

def save_contents_to_file(contents, output_filename="combined_files.txt"):
    """
    Save all file contents to a single output file with compact format
    """
    with open(output_filename, 'w', encoding='utf-8') as output_file:
        for file_path, result in contents.items():
            if result['success']:
                output_file.write(f"// === FILE: {file_path} === //\n")
                output_file.write(result['content'])
                output_file.write(f"\n\n// === END OF {file_path} === //\n\n")
            else:
                output_file.write(f"// === ERROR: {file_path} === //\n")
                output_file.write(f"// {result['error']}\n\n")
    
    return output_filename

# List of files to copy
files_to_copy = [
    "middleware\\auth.js", 
    "routes\\auth.js", 
    "routes\\habits.js",
    "server.js",
    "package.json"
]

# Get contents from all files
contents = copy_multiple_files(files_to_copy)

# Save to output file
output_file = save_contents_to_file(contents, "ai_input.txt")

print(f"All file contents have been saved to: {output_file}")