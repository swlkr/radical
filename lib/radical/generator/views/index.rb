<<~ERB
  <a href="<%= new_#{plural}_path %>">New #{singular}</a>

  <table>
    <thead>
      #{th(leading: 6)}
      <th></th>
    </thead>
    <tbody>
      <% @#{plural}.each do |#{singular}| %>
        <tr>
          #{td(leading: 10)}
          <td>
            <a href="<%= #{plural}_path(#{singular}) %>">show</a>
            <a href="<%= edit_#{plural}_path(#{singular}) %>">edit</a>
            <%== form model: #{singular}, method: :delete do |f| %>
              <%== f.submit 'delete' %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
ERB
