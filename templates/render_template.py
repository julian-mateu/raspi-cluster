import jinja2
import sys

template_file_name = sys.argv[1]

with open(template_file_name) as template_file:
    template = jinja2.Template(template_file.read())

rendered_template = template.render(
    master_ip=sys.argv[2],
    node_ips=sys.argv[3:]
)

print(rendered_template)
