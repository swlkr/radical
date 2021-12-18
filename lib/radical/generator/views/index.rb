<<~ERB
  <a href="<%= new_#{snake_case}_path %>">New #{camel_case}</a>

  <table>
    <thead>
      #{th(leading: 4)}
      <th></th>
      <th></th>
      <th></th>
    </thead>
    <tbody>
      <% @#{snake_case}s.each do |#{snake_case}| %>
        <tr>
          #{td(leading: 8)}
          <td>
            <a href="<%= #{snake_case}_path(#{snake_case}) %>">show</a>
          </td>
          <td>
            <a href="<%= edit_#{snake_case}_path(#{snake_case}) %>">edit</a>
          </td>
          <td>
            <%== form model: #{snake_case}, method: :delete do |f| %>
              <%== f.submit 'delete' %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
ERB
